//! Killswitch: checks for a marker file and self-destructs if present.

const std = @import("std");
const logger = @import("logger.zig");

const KILLSWITCH_PATH = "/tmp/stop_hermes";

pub fn check() void {
    if (std.fs.cwd().access(KILLSWITCH_PATH, .{})) |_| {
        logger.warn("Killswitch file detected, self-destructing...", .{});
        // Delete self binary (best effort)
        const self_path = std.fs.selfExePathAlloc(std.heap.page_allocator) catch null;
        if (self_path) |p| {
            std.fs.cwd().deleteFile(p) catch {};
            std.heap.page_allocator.free(p);
        }
        // Delete log file
        std.fs.cwd().deleteFile("/var/log/hermes.log") catch {};
        // Exit
        std.process.exit(0);
    } else |_| {}
}
