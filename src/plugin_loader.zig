//! Dynamic plugin loader for .so files, supporting both disk and memory loading.

const std = @import("std");
const c = std.c;
const Allocator = std.mem.Allocator;

// C-compatible structs matching plugin.h
pub const PluginInfo = extern struct {
    name: [*:0]const u8,
    version: [*:0]const u8,
    description: [*:0]const u8,
};

pub const PluginContext = extern struct {
    args: [*][*:0]const u8,
    arg_count: c_int,
    working_dir: [*:0]const u8,
};

pub const PluginApi = extern struct {
    init: ?*const fn () callconv(.C) c_int,
    run: ?*const fn (*PluginContext, *?[*:0]u8) callconv(.C) c_int,
    cleanup: ?*const fn () callconv(.C) c_int,
    get_info: ?*const fn () callconv(.C) *PluginInfo,
};

pub const LoadedPlugin = struct {
    handle: ?*anyopaque,
    api: *PluginApi,

    pub fn deinit(self: *LoadedPlugin) void {
        if (self.handle) |h| {
            _ = c.dlclose(h);
        }
    }

    pub fn callInit(self: *LoadedPlugin) !void {
        if (self.api.init) |init_fn| {
            if (init_fn() != 0) return error.PluginInitFailed;
        }
    }

    pub fn callCleanup(self: *LoadedPlugin) void {
        if (self.api.cleanup) |cleanup_fn| {
            _ = cleanup_fn();
        }
    }

    pub fn callRun(self: *LoadedPlugin, args: [][]const u8) ![]u8 {
        const allocator = std.heap.page_allocator;

        // Convert args to C-compatible array
        var c_args = try allocator.alloc([*:0]const u8, args.len);
        defer allocator.free(c_args);
        for (args, 0..) |arg, i| {
            c_args[i] = (try allocator.dupeZ(u8, arg)).ptr;
        }
        defer for (c_args) |arg_ptr| {
            allocator.free(std.mem.span(arg_ptr));
        };

        var ctx = PluginContext{
            .args = c_args.ptr,
            .arg_count = @intCast(args.len),
            .working_dir = "/",
        };

        var result_ptr: ?[*:0]u8 = null;
        if (self.api.run) |run_fn| {
            const ret = run_fn(&ctx, &result_ptr);
            if (ret != 0) return error.PluginRunFailed;
        } else {
            return error.NoRunFunction;
        }

        if (result_ptr) |r| {
            const result = try allocator.dupe(u8, std.mem.span(r));
            // Free the C-allocated string (assuming strdup was used)
            c.free(r);
            return result;
        }
        return allocator.dupe(u8, "");
    }
};

/// Load plugin from disk path
pub fn loadFromDisk(path: []const u8) !LoadedPlugin {
    const handle = c.dlopen(@ptrCast(path.ptr), c.RTLD_NOW) orelse {
        return error.DlopenFailed;
    };
    errdefer _ = c.dlclose(handle);

    const sym = c.dlsym(handle, "plugin_api") orelse {
        _ = c.dlclose(handle);
        return error.SymbolNotFound;
    };

    const api: *PluginApi = @ptrCast(@alignCast(sym));
    return LoadedPlugin{ .handle = handle, .api = api };
}

/// Load plugin from memory using memfd_create
pub fn loadFromMemory(data: []const u8) !LoadedPlugin {
    const allocator = std.heap.page_allocator;
    const fd = c.memfd_create("hermes_plugin", 0);
    if (fd < 0) return error.MemfdCreateFailed;
    defer c.close(fd);

    try std.os.write(fd, data);

    const path = try std.fmt.allocPrint(allocator, "/proc/self/fd/{d}", .{fd});
    defer allocator.free(path);

    return loadFromDisk(path);
}
