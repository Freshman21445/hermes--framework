//! Task dispatcher: receives a task and routes it to the appropriate plugin.
//! In Phase 1, we just log the task and send a dummy result.

const std = @import("std");
const protocol = @import("network/protocol.zig");
const logger = @import("utils/logger.zig");
const Client = @import("network/client.zig").Client;

pub fn dispatch(client: *Client, task: protocol.Task) !void {
    logger.info("Dispatching task {s} to plugin {s}", .{ task.task_id, task.plugin });
    // Here we would load the plugin and execute it.
    // For now, just send a success result with placeholder output.
    const result = protocol.TaskResult{
        .task_id = task.task_id,
        .success = true,
        .output = "Plugin execution not implemented in Phase 1",
    };
    try client.sendResult(result);
}
