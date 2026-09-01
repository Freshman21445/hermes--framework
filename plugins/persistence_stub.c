// Stub for persistence (disabled for testing).
#include "plugin.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static PluginInfo info = {
    .name = "persistence_stub",
    .version = "1.0",
    .description = "Persistence stub (disabled)"
};

int init(void) { return 0; }

int run(PluginContext* ctx, char** result) {
    fprintf(stderr, "Persistence disabled (TEST_ONLY)\n");
    *result = strdup("{\"status\":\"stub\"}");
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
