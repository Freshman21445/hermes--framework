//! Change the process name to appear legitimate.

const std = @import("std");
const c = std.c;

pub fn spoofName(comptime name: []const u8) void {
    _ = c.prctl(c.PR_SET_NAME, name.ptr, 0, 0, 0);
}
