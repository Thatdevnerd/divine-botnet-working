package main

import (
    "fmt"
    "net"
    "time"
)

// Test script to simulate bot connections
func testBotConnection() {
    fmt.Println("Testing bot connection...")
    
    // Connect to the CNC server
    conn, err := net.Dial("tcp", "185.247.117.214:59666")
    if err != nil {
        fmt.Printf("Failed to connect: %v\n", err)
        return
    }
    defer conn.Close()
    
    // Send bot handshake (4 bytes: 0x00 0x00 0x00 0x01)
    handshake := []byte{0x00, 0x00, 0x00, 0x01}
    _, err = conn.Write(handshake)
    if err != nil {
        fmt.Printf("Failed to send handshake: %v\n", err)
        return
    }
    
    // Send source length (0 for empty source)
    sourceLen := []byte{0x00}
    _, err = conn.Write(sourceLen)
    if err != nil {
        fmt.Printf("Failed to send source length: %v\n", err)
        return
    }
    
    fmt.Println("Handshake sent successfully")
    
    // Simulate ping-pong for a few iterations
    for i := 0; i < 5; i++ {
        // Send ping (1 byte)
        ping := []byte{0x01}
        _, err = conn.Write(ping)
        if err != nil {
            fmt.Printf("Failed to send ping %d: %v\n", i+1, err)
            return
        }
        
        // Read pong (1 byte)
        pong := make([]byte, 1)
        n, err := conn.Read(pong)
        if err != nil {
            fmt.Printf("Failed to read pong %d: %v\n", i+1, err)
            return
        }
        if n != 1 {
            fmt.Printf("Incomplete pong %d: got %d bytes\n", i+1, n)
            return
        }
        
        fmt.Printf("Ping-pong %d successful (sent: %x, received: %x)\n", i+1, ping[0], pong[0])
        time.Sleep(1 * time.Second)
    }
    
    fmt.Println("Test completed successfully!")
}

func main() {
    testBotConnection()
}
