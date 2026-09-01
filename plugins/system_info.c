// System information plugin: returns kernel, OS, CPU, memory info as JSON.
#include "plugin.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/utsname.h>
#include <unistd.h>

static PluginInfo info = {
    .name = "system_info",
    .version = "1.0",
    .description = "Gather system information"
};

int init(void) { return 0; }

static char* read_file(const char* path, int max_len) {
    FILE* f = fopen(path, "r");
    if (!f) return strdup("unknown");
    char* buf = malloc(max_len);
    if (!buf) { fclose(f); return strdup("unknown"); }
    size_t n = fread(buf, 1, max_len-1, f);
    buf[n] = '\0';
    fclose(f);
    return buf;
}

int run(PluginContext* ctx, char** result) {
    struct utsname uts;
    if (uname(&uts) != 0) {
        *result = strdup("{\"error\":\"uname failed\"}");
        return -1;
    }

    char* os_release = read_file("/etc/os-release", 4096);
    char* cpuinfo = read_file("/proc/cpuinfo", 4096);
    char* meminfo = read_file("/proc/meminfo", 4096);

    // Build JSON (simplified; in production use a JSON library)
    char* json = malloc(8192);
    snprintf(json, 8192,
        "{\"kernel\":\"%s\",\"os_release\":\"%s\",\"cpuinfo\":\"%s\",\"meminfo\":\"%s\"}",
        uts.release, os_release, cpuinfo, meminfo);

    free(os_release);
    free(cpuinfo);
    free(meminfo);
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
