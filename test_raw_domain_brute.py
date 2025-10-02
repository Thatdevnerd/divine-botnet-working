#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import socket
import time
import struct

def send_brute_attempt_report():
    """Send a brute attempt report to scanListen on localhost"""
    try:
        # Connect to scanListen on localhost:3912
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect(('127.0.0.1', 3912))
        
        print("Connected to scanListen on localhost:3912")
        
        # Send brute attempt report (flag=1, IP, port, empty username/password)
        brute_flag = struct.pack('B', 1)  # Flag to indicate brute attempt
        test_ip = socket.inet_aton('192.168.1.100')  # 4 bytes
        test_port = struct.pack('>H', 23)  # 2 bytes, big endian
        
        # Empty username/password for brute attempts
        zero_len = struct.pack('B', 0)  # username length = 0
        zero_len2 = struct.pack('B', 0)  # password length = 0
        
        # Construct the message
        message = brute_flag + test_ip + test_port + zero_len + zero_len2
        
        print("Sending brute attempt report: IP=192.168.1.100, Port=23")
        sock.send(message)
        
        # Wait for response
        time.sleep(1)
        
        sock.close()
        print("Brute attempt report sent successfully")
        
    except Exception as e:
        print("Error sending brute attempt report: " + str(e))

if __name__ == "__main__":
    send_brute_attempt_report()

