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
print(f"Domain: {domain}")
print(f"Length: {len(domain)}")
print(f"Obfuscated: {repr(obf_domain)}")
print(f"C format: ", end="")
for byte in obf_domain:
    print(f"\\x{byte:02x}", end="")
print()

# Obfuscate the port (3912 = 0x0F48 in network byte order)
port_bytes = bytes([0x0F, 0x48])
obf_port = obfuscate(port_bytes)
print(f"\nPort: 3912 (0x0F48)")
print(f"Obfuscated: {repr(obf_port)}")
print(f"C format: ", end="")
for byte in obf_port:
    print(f"\\x{byte:02X}", end="")
print()

