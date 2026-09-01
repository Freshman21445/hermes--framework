// Network scanner plugin: simple ICMP ping sweep using system ping command.
// Returns JSON array of online hosts.
#include "plugin.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static PluginInfo info = {
    .name = "network_scanner",
    .version = "1.0",
    .description = "Ping sweep a subnet"
};

int init(void) { return 0; }

// Helper to check if IP is alive using ping -c 1 -W 1
static int is_alive(const char* ip) {
    char cmd[256];
    snprintf(cmd, sizeof(cmd), "ping -c 1 -W 1 %s > /dev/null 2>&1", ip);
    return system(cmd) == 0;
}

int run(PluginContext* ctx, char** result) {
    if (ctx->arg_count < 1) {
        *result = strdup("{\"error\":\"missing IP range\"}");
        return -1;
    }
    const char* ip_range = ctx->args[0]; // e.g., "10.0.0.0/24"
    // For simplicity, assume last octet range 1-254 on a /24
    // Parse base IP
    char base_ip[64];
    strncpy(base_ip, ip_range, sizeof(base_ip)-1);
    base_ip[sizeof(base_ip)-1] = '\0';
    // Find last dot
    char* dot = strrchr(base_ip, '.');
    if (!dot) {
        *result = strdup("{\"error\":\"invalid IP range\"}");
        return -1;
    }
    *dot = '\0'; // now base_ip is like "10.0.0"

    char** online = malloc(254 * sizeof(char*));
    int count = 0;
    char ip[64];
    for (int i = 1; i <= 254; i++) {
        snprintf(ip, sizeof(ip), "%s.%d", base_ip, i);
        if (is_alive(ip)) {
            online[count++] = strdup(ip);
        }
    }

    // Build JSON array
    size_t bufsize = 256 + count * 20;
    char* json = malloc(bufsize);
    char* p = json;
    p += snprintf(p, bufsize, "{\"online\":[");
    for (int i = 0; i < count; i++) {
        p += snprintf(p, bufsize - (p-json), "\"%s\"", online[i]);
        if (i < count-1) p += snprintf(p, bufsize - (p-json), ",");
        free(online[i]);
    }
    p += snprintf(p, bufsize - (p-json), "]}");
    free(online);

    *result = json;
    return 0;
}

int cleanup(void) { return 0; }
PluginInfo* get_info(void) { return &info; }

__attribute__((visibility("default"))) PluginApi plugin_api = {
    .init = init,
    .run = run,
    .cleanup = cleanup,
    .get_info = get_info
};
