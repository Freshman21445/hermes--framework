//! Defines message structures exchanged between agent and server.

const std = @import("std");

// Registration request payload
pub const RegisterRequest = struct {
    hostname: []const u8,
    os: []const u8,
    kernel_version: []const u8,
    ip: []const u8,
};

// Registration response
pub const RegisterResponse = struct {
    agent_id: []const u8,
    session_key: []const u8, // base64 encoded or raw? We'll assume base64 string for JSON transport
};

// Heartbeat request
pub const HeartbeatRequest = struct {
    agent_id: []const u8,
    timestamp: i64,
    status: []const u8,
};

// Task as received from server
pub const Task = struct {
    task_id: []const u8,
    plugin: []const u8,
    arguments: []const []const u8,
};

// Result sent back to server
pub const TaskResult = struct {
    task_id: []const u8,
    success: bool,
    output: []const u8,
};
