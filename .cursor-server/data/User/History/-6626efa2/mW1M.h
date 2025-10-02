#pragma once

#include <stdio.h>
#include <time.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdarg.h>

#ifdef DEBUG

// Global log file handle
extern FILE *debug_log_file;

// Initialize debug logging
void debug_log_init(const char *log_filename);

// Close debug logging
void debug_log_close(void);

// Debug log function with timestamp
void debug_log(const char *format, ...);

// Macro for easy debug logging
#define DEBUG_LOG(fmt, ...) debug_log("[%s:%d] " fmt, __FILE__, __LINE__, ##__VA_ARGS__)

// Self-replication specific debug macros
#define SELFREP_DEBUG_LOG(fmt, ...) debug_log("[SELFREP] " fmt, ##__VA_ARGS__)
#define SCANNER_DEBUG_LOG(fmt, ...) debug_log("[SCANNER] " fmt, ##__VA_ARGS__)
#define CONNECTION_DEBUG_LOG(fmt, ...) debug_log("[CONNECTION] " fmt, ##__VA_ARGS__)

#else

// No-op macros when DEBUG is not defined
#define debug_log_init(filename)
#define debug_log_close()
#define debug_log(fmt, ...)
#define DEBUG_LOG(fmt, ...)
#define SELFREP_DEBUG_LOG(fmt, ...)
#define SCANNER_DEBUG_LOG(fmt, ...)
#define CONNECTION_DEBUG_LOG(fmt, ...)

#endif
