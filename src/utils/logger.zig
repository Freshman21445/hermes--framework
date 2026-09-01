//! Simple file logger with levels and timestamps.

const std = @import("std");
const Allocator = std.mem.Allocator;
const time = std.time;

pub const Level = enum {
    INFO,
    WARN,
    ERROR,
    DEBUG,
};

var log_file: ?std.fs.File = null;
var allocator: Allocator = undefined;

pub fn init() !void {
    allocator = std.heap.page_allocator;
    // Open or create log file in append mode
    log_file = try std.fs.cwd().openFile("/var/log/hermes.log", .{
        .mode = .write_only,
        .create = true,
        .append = true,
    });
}

pub fn deinit() void {
    if (log_file) |f| f.close();
}

fn log(level: Level, comptime fmt: []const u8, args: anytype) void {
    if (log_file) |f| {
        const timestamp = time.timestamp();
        const writer = f.writer();
        const level_str = switch (level) {
            .INFO => "INFO",
            .WARN => "WARN",
            .ERROR => "ERROR",
            .DEBUG => "DEBUG",
        };
        writer.print("[{d}] [{s}] ", .{ timestamp, level_str }) catch return;
        writer.print(fmt, args) catch return;
        writer.writeByte('\n') catch return;
    }
}

pub fn info(comptime fmt: []const u8, args: anytype) void {
    log(.INFO, fmt, args);
}
pub fn warn(comptime fmt: []const u8, args: anytype) void {
    log(.WARN, fmt, args);
}
pub fn err(comptime fmt: []const u8, args: anytype) void {
    log(.ERROR, fmt, args);
}
pub fn debug(comptime fmt: []const u8, args: anytype) void {
    log(.DEBUG, fmt, args);
}
