#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import socket
import time
import struct

def send_manual_scan_report():
    """Send a manual scan report to scanListen to test the complete flow"""
    try:
        # Connect to scanListen on localhost:3912
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect(('localhost', 3912))
        
        print("Connected to scanListen on port 3912")
        
        # Send scan report in the exact format expected by scanListen
        # Format: Zero byte (1) + IP (4 bytes) + Port (2 bytes) + Username length (1 byte) + Username + Password length (1 byte) + Password
        
        # Zero byte (required by the protocol)
        zero_byte = struct.pack('B', 0)
        
        # Test IP and port
        test_ip = socket.inet_aton('192.168.1.100')  # 4 bytes
        test_port = struct.pack('>H', 23)  # 2 bytes, big endian
        
        # Username and password
        username = b'root'
        password = b'admin'
        username_len = struct.pack('B', len(username))  # 1 byte
        password_len = struct.pack('B', len(password))  # 1 byte
        
        # Construct the complete message
        message = zero_byte + test_ip + test_port + username_len + username + password_len + password
        
        print("Sending manual scan report: IP=192.168.1.100, Port=23, User=root, Pass=admin")
        sock.send(message)
        
        # Wait for response
        time.sleep(1)
        
        sock.close()
        print("Manual scan report sent successfully")
        
    except Exception as e:
        print("Error sending manual scan report: " + str(e))

if __name__ == "__main__":
    send_manual_scan_report()
