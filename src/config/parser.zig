//! Configuration parser for the agent.
//! Reads a JSON file and populates a Config struct.

const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Config = struct {
    server_ip: []const u8,
    server_port: u16,
    dns_fallback: ?[]const u8 = null,
    heartbeat_interval: u32, // seconds
};

/// Load configuration from a JSON file.
pub fn load(path: []const u8) !Config {
    const allocator = std.heap.page_allocator;

    // Open file
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    // Read entire file
    const contents = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(contents);

    // Parse JSON
    var parser = std.json.Parser.init(allocator, false);
    defer parser.deinit();

    var tree = try parser.parse(contents);
    defer tree.deinit();

    const root = tree.root;
    const obj = root.object;

    // Extract fields with defaults
    const server_ip = obj.get("server_ip").?.string;
    const server_port = @as(u16, @intCast(obj.get("server_port").?.integer));
    const heartbeat_interval = @as(u32, @intCast(obj.get("heartbeat_interval").?.integer));

    // Optional DNS fallback
    var dns_fallback: ?[]const u8 = null;
    if (obj.get("dns_fallback")) |dns| {
        dns_fallback = dns.string;
    }

    return Config{
        .server_ip = try allocator.dupe(u8, server_ip),
        .server_port = server_port,
        .dns_fallback = dns_fallback,
        .heartbeat_interval = heartbeat_interval,
    };
}
