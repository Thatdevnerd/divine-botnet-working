package main

import (
	"errors"
	"time"

	"github.com/syrinsecurity/gologger"
)

func main() {

	//Start the service worker
	//Leave the path blank for loggers you do not want to use
	go gologger.Service("./error.log", "", "")

	gologger.Write(gologger.LogError, "error data")
	gologger.WritePrint(gologger.LogError, "This will write the data and print it")

	//Quick logger syntax
	gologger.Error.Write(errors.New("example error"))

	gologger.Error.Write(errors.New("data types can be mixed"), time.Now().Unix())

	//Due to the program running concurrently we are going to wait to allow time for the logs to be written. Logs are written extremal fast but due to this example application being only a few lines with minimal computation the main thread finishes very fast.
	for {
		if gologger.QueueSize() == 0 {
			break
		}

		time.Sleep(time.Millisecond * 100)
	}
}
