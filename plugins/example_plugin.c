// Example plugin demonstrating the API.
#include "plugin.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static PluginInfo info = {
    .name = "example",
    .version = "1.0",
    .description = "Example plugin for Hermes"
};

int init(void) {
    printf("[example] init called\n");
    return 0;
}

int run(PluginContext* ctx, char** result) {
    printf("[example] run called with %d args\n", ctx->arg_count);
    for (int i = 0; i < ctx->arg_count; i++) {
        printf("  arg[%d] = %s\n", i, ctx->args[i]);
    }
    // Return a simple JSON string
    const char* json = "{\"status\":\"ok\",\"plugin\":\"example\"}";
    *result = strdup(json);
    return 0;
}

int cleanup(void) {
    printf("[example] cleanup called\n");
    return 0;
}

PluginInfo* get_info(void) {
    return &info;
}

// Export the PluginApi symbol
__attribute__((visibility("default"))) PluginApi plugin_api = {
    .init = init,
    .run = run,
    .cleanup = cleanup,
    .get_info = get_info
};
