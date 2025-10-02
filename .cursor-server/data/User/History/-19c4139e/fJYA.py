#!/usr/bin/env python3
import socket
import time
import struct

def send_scan_report():
    """Send a test scan report to scanListen"""
    try:
        # Connect to scanListen on localhost:3912
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect(('localhost', 3912))
        
        print("✅ Connected to scanListen on port 3912")
        
        # Send test scan report data
        # Format: IP (4 bytes) + Port (2 bytes) + Username length (1 byte) + Username + Password length (1 byte) + Password
        test_ip = socket.inet_aton('192.168.1.100')  # 4 bytes
        test_port = struct.pack('>H', 23)  # 2 bytes, big endian
        username = b'root'
        password = b'admin'
        username_len = struct.pack('B', len(username))  # 1 byte
        password_len = struct.pack('B', len(password))  # 1 byte
        
        # Construct the message
        message = test_ip + test_port + username_len + username + password_len + password
        
        print(f"📤 Sending test scan report: IP=192.168.1.100, Port=23, User=root, Pass=admin")
        sock.send(message)
        
        # Wait for response
        time.sleep(1)
        
        sock.close()
        print("✅ Test scan report sent successfully")
        
    except Exception as e:
        print(f"❌ Error sending scan report: {e}")

if __name__ == "__main__":
    send_scan_report()
