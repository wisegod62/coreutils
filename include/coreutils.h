#ifndef COREUTILS_H
#define COREUTILS_H

#define _POSIX_C_SOURCE 200809L

#include <limits.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

/* --- Utility Macros --- */
#define UNUSED(x) (void)(x)
#define ARRAY_SIZE(arr) (sizeof(arr) / sizeof(arr[0]))

/* --- Shared Function Declarations --- */

/* Diagnostic Reporting */
void p_error(const char *utility, const char *msg);

/* Safe Memory Management */
void *xmalloc(size_t size);
char *xstrdup(const char *s);

/* Signal-Interrupt Safe I/O Operations */
ssize_t safe_read(int fd, void *buf, size_t count);
ssize_t safe_write(int fd, const void *buf, size_t count);

/* POSIX File Type Interrogation */
const char *get_posix_file_type(mode_t mode);

/*
 * POSIX Mode String Parser
 * Parses octal and symbolic mode strings.
 * Returns the final mode_t bitmask, or returns (mode_t)-1 on parse error.
 */
mode_t parse_posix_mode(const char *mode_str, mode_t initial_mode);

#endif /* COREUTILS_H */
