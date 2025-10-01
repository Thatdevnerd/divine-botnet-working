#!/bin/bash

# Test script for the debug version of scanListen
echo "=== Testing Debug scanListen ==="

# Create a small test target file
cat > test_targets.txt << EOF
192.168.1.1:23 admin:admin
192.168.1.2:2222 root:123456
10.0.0.1:23 user:pass
8.8.8.8:23 test:test
1.1.1.1:2222 admin:password
EOF

echo "Created test targets file with 5 targets"
echo "Targets:"
cat test_targets.txt

echo ""
echo "Starting debug scanListen..."
echo "This will simulate connections and track successes/failures"
echo ""

# Run the debug version
./scanListen_debug < test_targets.txt

echo ""
echo "=== Debug Test Complete ==="
echo "Check the generated log files:"
ls -la /root/loader/debug_*.log /root/loader/success_*.log 2>/dev/null || echo "No log files found"

echo ""
echo "Debug log content:"
if [ -f /root/loader/debug_*.log ]; then
    cat /root/loader/debug_*.log
else
    echo "No debug log found"
fi

echo ""
echo "Success log content:"
if [ -f /root/loader/success_*.log ]; then
    cat /root/loader/success_*.log
else
    echo "No success log found"
fi

# Cleanup
rm -f test_targets.txt
