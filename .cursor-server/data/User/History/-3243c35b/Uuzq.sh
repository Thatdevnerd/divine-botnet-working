#!/bin/bash

# Comprehensive Debug Monitor for Cyka Loader
# Monitors all execution responses and binary activities

echo "=== CYKA LOADER DEBUG MONITOR ==="
echo "Monitoring all binary execution responses and activities..."
echo "Press Ctrl+C to stop monitoring"
echo ""

# Create log files if they don't exist
touch /tmp/loader_debug.log /tmp/execution_tracking.log /tmp/connection_monitor.log

# Function to display real-time logs
monitor_logs() {
    echo "=== REAL-TIME LOG MONITORING ==="
    echo "Watching for binary execution responses..."
    echo ""
    
    # Monitor all three log files simultaneously
    tail -f /tmp/loader_debug.log /tmp/execution_tracking.log /tmp/connection_monitor.log 2>/dev/null | while read line; do
        timestamp=$(date '+%H:%M:%S')
        echo "[$timestamp] $line"
    done
}

# Function to show current statistics
show_stats() {
    echo "=== CURRENT STATISTICS ==="
    
    if [ -f /tmp/execution_tracking.log ]; then
        echo "Binary Executions:"
        echo "  Success: $(grep -c "EXEC_SUCCESS" /tmp/execution_tracking.log 2>/dev/null || echo "0")"
        echo "  Failed:  $(grep -c "EXEC_FAILED" /tmp/execution_tracking.log 2>/dev/null || echo "0")"
        echo ""
        
        echo "Downloads:"
        echo "  WGET Success: $(grep -c "DOWNLOAD_SUCCESS.*WGET" /tmp/execution_tracking.log 2>/dev/null || echo "0")"
        echo "  WGET Failed:  $(grep -c "DOWNLOAD_FAILED.*WGET" /tmp/execution_tracking.log 2>/dev/null || echo "0")"
        echo "  TFTP Success: $(grep -c "DOWNLOAD_SUCCESS.*TFTP" /tmp/execution_tracking.log 2>/dev/null || echo "0")"
        echo "  TFTP Failed:  $(grep -c "DOWNLOAD_FAILED.*TFTP" /tmp/execution_tracking.log 2>/dev/null || echo "0")"
        echo ""
    fi
    
    if [ -f /tmp/connection_monitor.log ]; then
        echo "Connection Attempts:"
        echo "  Total: $(wc -l < /tmp/connection_monitor.log 2>/dev/null || echo "0")"
        echo ""
    fi
    
    echo "Active CNC Connections:"
    netstat -an | grep -E ":666|:59666" | grep ESTABLISHED | wc -l
    echo ""
}

# Function to show recent binary execution responses
show_recent_executions() {
    echo "=== RECENT BINARY EXECUTION RESPONSES ==="
    if [ -f /tmp/execution_tracking.log ]; then
        tail -20 /tmp/execution_tracking.log | grep -E "EXEC_SUCCESS|EXEC_FAILED"
    else
        echo "No execution logs found yet."
    fi
    echo ""
}

# Function to show download activities
show_download_activities() {
    echo "=== RECENT DOWNLOAD ACTIVITIES ==="
    if [ -f /tmp/execution_tracking.log ]; then
        tail -20 /tmp/execution_tracking.log | grep -E "DOWNLOAD_SUCCESS|DOWNLOAD_FAILED"
    else
        echo "No download logs found yet."
    fi
    echo ""
}

# Main menu
while true; do
    clear
    echo "=== CYKA LOADER DEBUG MONITOR ==="
    echo "1. Monitor real-time logs"
    echo "2. Show current statistics"
    echo "3. Show recent binary executions"
    echo "4. Show download activities"
    echo "5. View all log files"
    echo "6. Clear logs and restart"
    echo "7. Exit"
    echo ""
    read -p "Select option (1-7): " choice
    
    case $choice in
        1)
            monitor_logs
            ;;
        2)
            show_stats
            read -p "Press Enter to continue..."
            ;;
        3)
            show_recent_executions
            read -p "Press Enter to continue..."
            ;;
        4)
            show_download_activities
            read -p "Press Enter to continue..."
            ;;
        5)
            echo "=== ALL LOG FILES ==="
            echo "--- LOADER DEBUG LOG ---"
            cat /tmp/loader_debug.log 2>/dev/null || echo "No debug log found"
            echo ""
            echo "--- EXECUTION TRACKING LOG ---"
            cat /tmp/execution_tracking.log 2>/dev/null || echo "No execution log found"
            echo ""
            echo "--- CONNECTION MONITOR LOG ---"
            cat /tmp/connection_monitor.log 2>/dev/null || echo "No connection log found"
            read -p "Press Enter to continue..."
            ;;
        6)
            echo "Clearing all logs..."
            > /tmp/loader_debug.log
            > /tmp/execution_tracking.log
            > /tmp/connection_monitor.log
            echo "Logs cleared. Restarting monitoring..."
            sleep 2
            ;;
        7)
            echo "Exiting debug monitor..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please select 1-7."
            sleep 1
            ;;
    esac
done


