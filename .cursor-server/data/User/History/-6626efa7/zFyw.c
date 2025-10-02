#include "debug_log.h"

#ifdef DEBUG

FILE *debug_log_file = NULL;

void debug_log_init(const char *log_filename)
{
    if (debug_log_file != NULL) {
        fclose(debug_log_file);
    }
    
    debug_log_file = fopen(log_filename, "a");
    if (debug_log_file == NULL) {
        // Fallback to stderr if file opening fails
        debug_log_file = stderr;
    }
    
    // Write initial log entry
    time_t now = time(NULL);
    struct tm *tm_info = localtime(&now);
    char timestamp[64];
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", tm_info);
    
    fprintf(debug_log_file, "\n=== DEBUG LOG STARTED [%s] PID: %d ===\n", timestamp, getpid());
    fflush(debug_log_file);
}

void debug_log_close(void)
{
    if (debug_log_file != NULL && debug_log_file != stderr) {
        time_t now = time(NULL);
        struct tm *tm_info = localtime(&now);
        char timestamp[64];
        strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", tm_info);
        
        fprintf(debug_log_file, "=== DEBUG LOG ENDED [%s] ===\n", timestamp);
        fclose(debug_log_file);
        debug_log_file = NULL;
    }
}

void debug_log(const char *format, ...)
{
    if (debug_log_file == NULL) {
        return;
    }
    
    time_t now = time(NULL);
    struct tm *tm_info = localtime(&now);
    char timestamp[64];
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", tm_info);
    
    // Write timestamp
    fprintf(debug_log_file, "[%s] ", timestamp);
    
    // Write the actual message
    va_list args;
    va_start(args, format);
    vfprintf(debug_log_file, format, args);
    va_end(args);
    
    // Add newline and flush
    fprintf(debug_log_file, "\n");
    fflush(debug_log_file);
}

#endif
