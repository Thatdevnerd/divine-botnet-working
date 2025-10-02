#!/bin/bash

# Self-Replication Debug Startup Script
# This script starts the bot with debug logging for self-replication

echo "🚀 Starting Self-Replication Debug Bot..."

# Check if debug version exists
if [ ! -f "./selfrep_debug" ]; then
    echo "❌ Debug version not found. Building..."
    make -f Makefile_debug clean
    make -f Makefile_debug
    if [ $? -ne 0 ]; then
        echo "❌ Failed to build debug version"
        exit 1
    fi
fi

# Create log directory if it doesn't exist
mkdir -p /tmp
touch /tmp/selfrep_debug.log

# Set optimal system limits
ulimit -n 999999
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse

echo "📝 Debug log file: /tmp/selfrep_debug.log"
echo "🔍 Starting self-replication debug bot..."

# Start the debug version
./selfrep_debug selfrep_debug &

BOT_PID=$!
echo "🤖 Bot started with PID: $BOT_PID"

# Monitor the bot and log file
echo "📊 Monitoring bot status and debug log..."
echo "Press Ctrl+C to stop monitoring (bot will continue running)"

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping monitoring..."
    echo "Bot is still running with PID: $BOT_PID"
    echo "To stop the bot: kill $BOT_PID"
    echo "Debug log: /tmp/selfrep_debug.log"
    exit 0
}

# Set trap for cleanup
trap cleanup INT

# Monitor loop
while true; do
    sleep 5
    echo "=== Self-Rep Debug Status ==="
    echo "Bot PID: $BOT_PID"
    echo "Bot Status: $(ps -p $BOT_PID > /dev/null 2>&1 && echo "RUNNING" || echo "STOPPED")"
    echo "Log Size: $(ls -lh /tmp/selfrep_debug.log 2>/dev/null | awk '{print $5}' || echo 'N/A')"
    echo "Last 3 log entries:"
    tail -3 /tmp/selfrep_debug.log 2>/dev/null || echo "No log entries yet"
    echo "============================="
done
