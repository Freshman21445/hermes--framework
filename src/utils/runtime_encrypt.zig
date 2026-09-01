//! Runtime code encryption: decrypt plugin binaries in memory before loading.
const std = @import("std");
const crypto = @import("../network/crypto.zig");

pub fn loadEncryptedPlugin(path: []const u8, key: crypto.Key) ![]u8 {
    const allocator = std.heap.page_allocator;
    // Read encrypted plugin file
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    const encrypted = try file.readToEndAlloc(allocator, 1024*1024);
    defer allocator.free(encrypted);

    // Decrypt
    const decrypted = try crypto.decrypt(encrypted, key, allocator);
    return decrypted;
}
