package main

import (
	"github.com/syrinsecurity/gologger"
)

type structExample struct {
	Feild1 string
	Feild2 string
}

func main() {
	//Create a new custom logger
	log := gologger.NewCustomLogger("./logs-", ".txt", 0)

	//This will make the filename update every month for example: logs-Jul-2020.txt
	gologger.SetNameConventionMonthYear(log)

	//Start the logger service on another goroutine
	go log.Service()

	//Make sure to close the logger
	defer log.Close()

	//write multipule values to the log with any data type
	log.Write("test", 1, 2, 2)

	//Convert any object to JSON and write it to the log
	log.WriteJSON(structExample{
		Feild1: "value1",
		Feild2: "value2",
	})

	//Byte arrays are written directly to the file, meaning no additional formating like fmt would
	log.Write([]byte{0, 3, 86, 32})

}
