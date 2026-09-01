// File integrity plugin: computes SHA-256 hash of a file.
#include "plugin.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <openssl/sha.h>

static PluginInfo info = {
    .name = "file_integrity",
    .version = "1.0",
    .description = "Compute SHA-256 hash of a file"
};

int init(void) { return 0; }

int run(PluginContext* ctx, char** result) {
    if (ctx->arg_count < 1) {
        *result = strdup("{\"error\":\"missing file path\"}");
        return -1;
    }
    const char* path = ctx->args[0];
    FILE* f = fopen(path, "rb");
    if (!f) {
        *result = strdup("{\"error\":\"cannot open file\"}");
        return -1;
    }

    SHA256_CTX sha256;
    SHA256_Init(&sha256);
    unsigned char buf[4096];
    size_t bytes_read;
    unsigned long total = 0;
    while ((bytes_read = fread(buf, 1, sizeof(buf), f)) > 0) {
        SHA256_Update(&sha256, buf, bytes_read);
        total += bytes_read;
    }
    fclose(f);

    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256_Final(hash, &sha256);

    char hash_hex[SHA256_DIGEST_LENGTH*2+1];
    for (int i = 0; i < SHA256_DIGEST_LENGTH; i++) {
        sprintf(hash_hex + i*2, "%02x", hash[i]);
    }

    char* json = malloc(512);
    snprintf(json, 512, "{\"path\":\"%s\",\"hash\":\"%s\",\"size\":%lu}", path, hash_hex, total);
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
