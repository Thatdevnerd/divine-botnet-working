#!/bin/bash

# Self-Replication Monitoring Script
# Real-time monitoring of self-replication activities

echo "🔍 Self-Replication Monitor"
echo "============================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_FILE="/tmp/selfrep_debug.log"

# Function to show status
show_status() {
    echo -e "${CYAN}=== Self-Rep Status ===${NC}"
    
    # Check if bot is running
    BOT_PID=$(ps aux | grep selfrep_debug | grep -v grep | awk '{print $2}' | head -1)
    if [ ! -z "$BOT_PID" ]; then
        echo -e "${GREEN}✅ Bot running (PID: $BOT_PID)${NC}"
    else
        echo -e "${RED}❌ Bot not running${NC}"
    fi
    
    # Check scanner process
    SCANNER_PID=$(ps aux | grep scanner | grep -v grep | awk '{print $2}' | head -1)
    if [ ! -z "$SCANNER_PID" ]; then
        echo -e "${GREEN}✅ Scanner running (PID: $SCANNER_PID)${NC}"
    else
        echo -e "${YELLOW}⚠️  Scanner not detected${NC}"
    fi
    
    # Check log file
    if [ -f "$LOG_FILE" ]; then
        LOG_SIZE=$(ls -lh "$LOG_FILE" | awk '{print $5}')
        echo -e "${BLUE}📝 Log file: $LOG_SIZE${NC}"
        
        # Count different types of activities
        TOTAL_ENTRIES=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
        SCANNER_ENTRIES=$(grep -c "SCANNER" "$LOG_FILE" 2>/dev/null || echo "0")
        SELFREP_ENTRIES=$(grep -c "SELFREP" "$LOG_FILE" 2>/dev/null || echo "0")
        SUCCESSFUL_COMPROMISES=$(grep -c "successful compromise" "$LOG_FILE" 2>/dev/null || echo "0")
        BRUTE_FORCE_ATTEMPTS=$(grep -c "Attempting to brute force" "$LOG_FILE" 2>/dev/null || echo "0")
        
        echo -e "${BLUE}📊 Activities:${NC}"
        echo "   Total entries: $TOTAL_ENTRIES"
        echo "   Scanner activities: $SCANNER_ENTRIES"
        echo "   Self-rep activities: $SELFREP_ENTRIES"
        echo "   Successful compromises: $SUCCESSFUL_COMPROMISES"
        echo "   Brute force attempts: $BRUTE_FORCE_ATTEMPTS"
    else
        echo -e "${RED}❌ Log file not found${NC}"
    fi
    
    echo ""
}

# Function to show recent activity
show_recent() {
    echo -e "${CYAN}=== Recent Activity ===${NC}"
    if [ -f "$LOG_FILE" ] && [ -s "$LOG_FILE" ]; then
        echo "Last 5 entries:"
        tail -5 "$LOG_FILE" | while read line; do
            if echo "$line" | grep -q "successful compromise"; then
                echo -e "${GREEN}🎯 $line${NC}"
            elif echo "$line" | grep -q "Attempting to brute force"; then
                echo -e "${YELLOW}🔍 $line${NC}"
            elif echo "$line" | grep -q "connected to CNC"; then
                echo -e "${BLUE}🔗 $line${NC}"
            else
                echo "   $line"
            fi
        done
    else
        echo "No recent activity"
    fi
    echo ""
}

# Function to show successful compromises
show_compromises() {
    echo -e "${CYAN}=== Successful Compromises ===${NC}"
    if [ -f "$LOG_FILE" ]; then
        COMPROMISES=$(grep "successful compromise" "$LOG_FILE" 2>/dev/null)
        if [ ! -z "$COMPROMISES" ]; then
            echo "$COMPROMISES" | tail -10 | while read line; do
                echo -e "${GREEN}🎯 $line${NC}"
            done
        else
            echo "No successful compromises yet"
        fi
    else
        echo "Log file not found"
    fi
    echo ""
}

# Function to show target statistics
show_targets() {
    echo -e "${CYAN}=== Target Statistics ===${NC}"
    if [ -f "$LOG_FILE" ]; then
        # Extract unique IPs that were targeted
        TARGETS=$(grep "Attempting to brute force IP" "$LOG_FILE" 2>/dev/null | \
                  sed 's/.*IP \([0-9.]*\):.*/\1/' | sort | uniq -c | sort -nr)
        
        if [ ! -z "$TARGETS" ]; then
            echo "Most targeted IPs:"
            echo "$TARGETS" | head -10
        else
            echo "No target data available"
        fi
        
        # Extract successful credentials
        CREDS=$(grep "successful compromise" "$LOG_FILE" 2>/dev/null | \
                 sed 's/.*with auth \([^:]*\):\([^ ]*\).*/\1:\2/' | sort | uniq -c | sort -nr)
        
        if [ ! -z "$CREDS" ]; then
            echo ""
            echo "Most successful credentials:"
            echo "$CREDS" | head -5
        fi
    else
        echo "Log file not found"
    fi
    echo ""
}

# Function to start monitoring
start_monitoring() {
    echo -e "${CYAN}=== Real-time Monitoring ===${NC}"
    echo "Press Ctrl+C to stop monitoring"
    echo ""
    
    # Show initial status
    show_status
    
    # Monitor log file in real-time
    if [ -f "$LOG_FILE" ]; then
        tail -f "$LOG_FILE" | while read line; do
            # Color code different types of messages
            if echo "$line" | grep -q "successful compromise"; then
                echo -e "${GREEN}🎯 $line${NC}"
            elif echo "$line" | grep -q "Attempting to brute force"; then
                echo -e "${YELLOW}🔍 $line${NC}"
            elif echo "$line" | grep -q "connected to CNC"; then
                echo -e "${BLUE}🔗 $line${NC}"
            elif echo "$line" | grep -q "Scanner process started"; then
                echo -e "${CYAN}🚀 $line${NC}"
            elif echo "$line" | grep -q "Bot started"; then
                echo -e "${CYAN}🤖 $line${NC}"
            else
                echo "   $line"
            fi
        done
    else
        echo "Log file not found: $LOG_FILE"
        echo "Start the bot first: ./start_selfrep_debug.sh"
    fi
}

# Main menu
case "${1:-menu}" in
    "status")
        show_status
        ;;
    "recent")
        show_recent
        ;;
    "compromises")
        show_compromises
        ;;
    "targets")
        show_targets
        ;;
    "monitor"|"live")
        start_monitoring
        ;;
    "menu"|*)
        echo "Self-Replication Monitor"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  status      - Show current status"
        echo "  recent      - Show recent activity"
        echo "  compromises - Show successful compromises"
        echo "  targets     - Show target statistics"
        echo "  monitor     - Start real-time monitoring"
        echo "  live        - Alias for monitor"
        echo ""
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 monitor"
        echo "  $0 compromises"
        ;;
esac
