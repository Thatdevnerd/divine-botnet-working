package main

import (
	"time"

	"github.com/syrinsecurity/gologger"
)

func main() {

	logger, err := gologger.New("./file.log", 300)
	if err != nil {
		panic(err)
	}

	//All logs are separated by a new line "\n"
	logger.Write("This is some data.", []string{"a interface is allowed to be used", "fmt is used to format this data"}, 45, []int{1, 2, 3, 4})
	logger.WriteString("This will write all the input as text only rather than a array of items like logger.Write().", "This also accepts a interface")
	logger.WritePrint("This will write this data to the log file but also print it out with a timestamp")

	logger.WriteJSON(jsonObject{
		Name:      "John Doe",
		Email:     "johndoe@syrinsecurity.net",
		Timestamp: time.Now().Unix(),
	})

	//Due to the program running concurrently we are going to wait to allow time for the logs to be written. Logs are written extremal fast but due to this example application being only a few lines with minimal computation the main thread finishes very fast.
	for {
		if gologger.QueueSize() == 0 {
			break
		}

		time.Sleep(time.Millisecond * 100)
	}
}

type jsonObject struct {
	Name      string `json:"name"`
	Email     string `json:"email"`
	Timestamp int64  `json:"timestamp"`
}
