//! Network client for the agent. Handles TLS connection, registration,
//! heartbeat, and task result transmission.

const std = @import("std");
const net = std.net;
const tls = std.crypto.tls;
const json = std.json;
const Allocator = std.mem.Allocator;

const config = @import("../config/parser.zig");
const protocol = @import("protocol.zig");
const logger = @import("../utils/logger.zig");

pub const Client = struct {
    allocator: Allocator,
    config: config.Config,
    stream: ?net.Stream = null,
    tls_client: ?tls.Client = null,
    agent_id: []const u8 = "",
    session_key: []const u8 = "", // base64 string for now

    pub fn init(cfg: config.Config) !Client {
        return Client{
            .allocator = std.heap.page_allocator,
            .config = cfg,
        };
    }

    /// Establish TCP + TLS connection with exponential backoff (Step 6)
    pub fn connect(self: *Client) !void {
        var attempts: u32 = 0;
        while (attempts < 10) : (attempts += 1) {
            const stream = net.tcpConnectToHost(
                self.allocator,
                self.config.server_ip,
                self.config.server_port,
            ) catch |err| {
                logger.warn("TCP connect failed: {s}", .{@errorName(err)});
                std.time.sleep(std.time.ns_per_s * (1 << attempts));
                continue;
            };

            // Wrap in TLS
            var tls_client = tls.Client.init(stream, .{
                .host = self.config.server_ip,
                .trust = .none, // accept self-signed
            }) catch |err| {
                stream.close();
                logger.warn("TLS init failed: {s}", .{@errorName(err)});
                std.time.sleep(std.time.ns_per_s * (1 << attempts));
                continue;
            };

            // Perform handshake
            tls_client.handshake() catch |err| {
                stream.close();
                logger.warn("TLS handshake failed: {s}", .{@errorName(err)});
                std.time.sleep(std.time.ns_per_s * (1 << attempts));
                continue;
            };

            self.stream = stream;
            self.tls_client = tls_client;
            return;
        }
        return error.ConnectionFailed;
    }

    /// Send an HTTP POST request over TLS and return response body (helper)
    fn post(self: *Client, path: []const u8, body: []const u8) ![]u8 {
        const tls_conn = self.tls_client.?;
        const writer = tls_conn.writer();
        const reader = tls_conn.reader();

        // Build HTTP request manually
        const request = try std.fmt.allocPrint(self.allocator,
            "POST {s} HTTP/1.1\r\nHost: {s}\r\nContent-Type: application/json\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n{s}",
            .{ path, self.config.server_ip, body.len, body });
        defer self.allocator.free(request);

        try writer.writeAll(request);

        // Read response (simple: read until connection close)
        var response = std.ArrayList(u8).init(self.allocator);
        defer response.deinit();
        var buf: [4096]u8 = undefined;
        while (true) {
            const n = try reader.read(&buf);
            if (n == 0) break;
            try response.appendSlice(buf[0..n]);
        }

        // Find body (after \r\n\r\n)
        const resp = response.items;
        const header_end = std.mem.indexOf(u8, resp, "\r\n\r\n") orelse return error.InvalidResponse;
        return try self.allocator.dupe(u8, resp[header_end + 4 ..]);
    }

    /// Register with server (Step 7)
    pub fn register(self: *Client) !void {
        // Gather system info
        const hostname = try std.os.getHostName(self.allocator);
        defer self.allocator.free(hostname);

        const kernel = try getKernelVersion(self.allocator);
        defer self.allocator.free(kernel);

        const ip = try getLocalIP(self.allocator);
        defer self.allocator.free(ip);

        const req = protocol.RegisterRequest{
            .hostname = hostname,
            .os = "linux",
            .kernel_version = kernel,
            .ip = ip,
        };

        const body = try json.stringify(req, .{});
        defer self.allocator.free(body);

        const response = try self.post("/register", body);
        defer self.allocator.free(response);

        // Parse response
        var parser = json.Parser.init(self.allocator, false);
        defer parser.deinit();
        var tree = try parser.parse(response);
        defer tree.deinit();
        const obj = tree.root.object;

        self.agent_id = try self.allocator.dupe(u8, obj.get("agent_id").?.string);
        self.session_key = try self.allocator.dupe(u8, obj.get("session_key").?.string);
    }

    /// Send heartbeat and return optional task (Step 8)
    pub fn heartbeat(self: *Client) !?protocol.Task {
        const req = protocol.HeartbeatRequest{
            .agent_id = self.agent_id,
            .timestamp = std.time.timestamp(),
            .status = "alive",
        };

        const body = try json.stringify(req, .{});
        defer self.allocator.free(body);

        const response = try self.post("/heartbeat", body);
        defer self.allocator.free(response);

        // Check if response contains a task
        var parser = json.Parser.init(self.allocator, false);
        defer parser.deinit();
        var tree = try parser.parse(response);
        defer tree.deinit();
        const obj = tree.root.object;

        if (obj.get("task")) |task_val| {
            const task_obj = task_val.object;
            const task_id = task_obj.get("task_id").?.string;
            const plugin = task_obj.get("plugin").?.string;
            const args_array = task_obj.get("arguments").?.array;
            var args = std.ArrayList([]const u8).init(self.allocator);
            defer args.deinit();
            for (args_array.items) |arg| {
                try args.append(arg.string);
            }
            return protocol.Task{
                .task_id = try self.allocator.dupe(u8, task_id),
                .plugin = try self.allocator.dupe(u8, plugin),
                .arguments = try args.toOwnedSlice(),
            };
        }
        return null;
    }

    /// Send task result back to server
    pub fn sendResult(self: *Client, result: protocol.TaskResult) !void {
        const body = try json.stringify(result, .{});
        defer self.allocator.free(body);
        const response = try self.post("/result", body);
        defer self.allocator.free(response);
        // ignore response for now
    }
};

// Helper functions
fn getKernelVersion(allocator: Allocator) ![]u8 {
    var buf: [256]u8 = undefined;
    const uts = std.os.uname(&buf) catch return error.KernelInfoFailed;
    return allocator.dupe(u8, uts.release);
}

fn getLocalIP(allocator: Allocator) ![]u8 {
    // Use a simple method: get hostname then resolve
    const hostname = try std.os.getHostName(allocator);
    defer allocator.free(hostname);
    const addr_list = try std.net.getAddressList(allocator, hostname, 0);
    defer addr_list.deinit();
    if (addr_list.addrs.len == 0) return error.NoIP;
    return allocator.dupe(u8, addr_list.addrs[0].toString());
}
