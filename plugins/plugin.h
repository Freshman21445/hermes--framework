#ifndef PLUGIN_H
#define PLUGIN_H

#define PLUGIN_API_VERSION 1

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    const char* name;
    const char* version;
    const char* description;
} PluginInfo;

typedef struct {
    char** args;          // Array of argument strings
    int arg_count;        // Number of arguments
    const char* working_dir; // Current working directory
} PluginContext;

typedef struct {
    int (*init)(void);                                    // Called once on load
    int (*run)(PluginContext* ctx, char** result);        // Execute plugin, set *result to allocated JSON string
    int (*cleanup)(void);                                 // Called once on unload
    PluginInfo* (*get_info)(void);                        // Return plugin metadata
} PluginApi;

#ifdef __cplusplus
}
#endif

#endif // PLUGIN_H
