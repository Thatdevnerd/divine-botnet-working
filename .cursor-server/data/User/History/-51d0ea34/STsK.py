#!/usr/bin/env python3
"""
Simple CNC server for testing selfrep_debug bot
Listens on port 59666 and accepts connections from bots
"""

import socket
import threading
import time
import sys

class SimpleCNCServer:
    def __init__(self, host='0.0.0.0', port=59666):
        self.host = host
        self.port = port
        self.socket = None
        self.running = False
        self.connected_bots = 0
        
    def start(self):
        """Start the CNC server"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.socket.bind((self.host, self.port))
            self.socket.listen(5)
            self.running = True
            
            print(f"[CNC] Server started on {self.host}:{self.port}")
            print(f"[CNC] Waiting for bot connections...")
            
            while self.running:
                try:
                    client_socket, client_address = self.socket.accept()
                    self.connected_bots += 1
                    print(f"[CNC] Bot connected from {client_address[0]}:{client_address[1]} (Total: {self.connected_bots})")
                    
                    # Handle bot connection in a separate thread
                    bot_thread = threading.Thread(
                        target=self.handle_bot_connection,
                        args=(client_socket, client_address)
                    )
                    bot_thread.daemon = True
                    bot_thread.start()
                    
                except socket.error as e:
                    if self.running:
                        print(f"[CNC] Error accepting connection: {e}")
                    break
                    
        except Exception as e:
            print(f"[CNC] Failed to start server: {e}")
            sys.exit(1)
    
    def handle_bot_connection(self, client_socket, client_address):
        """Handle individual bot connection"""
        try:
            print(f"[CNC] Handling bot from {client_address[0]}:{client_address[1]}")
            
            # Keep connection alive and handle ping/pong
            while self.running:
                try:
                    # Set timeout for receiving data
                    client_socket.settimeout(10.0)
                    
                    # Try to receive data
                    data = client_socket.recv(1024)
                    if not data:
                        print(f"[CNC] Bot {client_address[0]}:{client_address[1]} disconnected")
                        break
                    
                    # Handle ping (empty data or length 0)
                    if len(data) == 0 or (len(data) == 2 and data == b'\x00\x00'):
                        print(f"[CNC] Received ping from {client_address[0]}:{client_address[1]}")
                        # Send pong back
                        client_socket.send(b'\x00\x00')
                    else:
                        print(f"[CNC] Received data from {client_address[0]}:{client_address[1]}: {data.hex()}")
                        
                except socket.timeout:
                    # Send ping to bot
                    try:
                        client_socket.send(b'\x00\x00')
                    except:
                        break
                except socket.error as e:
                    print(f"[CNC] Error with bot {client_address[0]}:{client_address[1]}: {e}")
                    break
                    
        except Exception as e:
            print(f"[CNC] Error handling bot {client_address[0]}:{client_address[1]}: {e}")
        finally:
            try:
                client_socket.close()
                self.connected_bots -= 1
                print(f"[CNC] Bot {client_address[0]}:{client_address[1]} disconnected (Remaining: {self.connected_bots})")
            except:
                pass
    
    def stop(self):
        """Stop the CNC server"""
        print("[CNC] Stopping server...")
        self.running = False
        if self.socket:
            self.socket.close()

if __name__ == "__main__":
    server = SimpleCNCServer()
    
    try:
        server.start()
    except KeyboardInterrupt:
        print("\n[CNC] Shutting down...")
        server.stop()
    except Exception as e:
        print(f"[CNC] Error: {e}")
        server.stop()
