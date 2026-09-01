//! Task dispatcher: receives a task, loads the requested plugin, executes it,
//! and sends the result back to the server.

const std = @import("std");
const protocol = @import("network/protocol.zig");
const logger = @import("utils/logger.zig");
const Client = @import("network/client.zig").Client;
const plugin_loader = @import("plugin_loader.zig");

pub fn dispatch(client: *Client, task: protocol.Task) !void {
    logger.info("Dispatching task {s} to plugin {s}", .{ task.task_id, task.plugin });

    // Build plugin path: assume plugins are in current directory or specified path.
    // For simplicity, we try to load from disk "plugins/<plugin>.so" or just "<plugin>.so"
    const allocator = std.heap.page_allocator;
    const plugin_path = try std.fmt.allocPrint(allocator, "plugins/{s}.so", .{task.plugin});
    defer allocator.free(plugin_path);

    // Load plugin from disk
    var plugin = plugin_loader.loadFromDisk(plugin_path) catch |err| {
        logger.err("Failed to load plugin '{s}': {s}", .{ task.plugin, @errorName(err) });
        const result = protocol.TaskResult{
            .task_id = task.task_id,
            .success = false,
            .output = "Failed to load plugin",
        };
        try client.sendResult(result);
        return;
    };
    defer plugin.deinit();

    // Initialize plugin
    plugin.callInit() catch |err| {
        logger.err("Plugin init failed: {s}", .{@errorName(err)});
        const result = protocol.TaskResult{
            .task_id = task.task_id,
            .success = false,
            .output = "Plugin init failed",
        };
        try client.sendResult(result);
        return;
    };
    defer plugin.callCleanup();

    // Execute plugin
    const output = plugin.callRun(task.arguments) catch |err| {
        logger.err("Plugin run failed: {s}", .{@errorName(err)});
        const result = protocol.TaskResult{
            .task_id = task.task_id,
            .success = false,
            .output = "Plugin run failed",
        };
        try client.sendResult(result);
        return;
    };
    defer allocator.free(output);

    // Send successful result
    const result = protocol.TaskResult{
        .task_id = task.task_id,
        .success = true,
        .output = output,
    };
    try client.sendResult(result);
}
