package gologger

import (
	"fmt"
	"os"
)

//Service handles the log events and writes them to disk. Leave errorLog blank if you do not want to use it, same applies to any other log
func Service(errorLog string, trafficLog string, criticalLog string) {

	var (
		errorLogEnabled    = true
		trafficLogEnabled  = true
		criticalLogEnabled = true

		errorFile    *os.File
		trafficFile  *os.File
		criticalFile *os.File
	)

	if len(errorLog) == 0 {
		errorLogEnabled = false
	}

	if len(trafficLog) == 0 {
		trafficLogEnabled = false
	}

	if len(criticalLog) == 0 {
		criticalLogEnabled = false
	}

	if errorLogEnabled == true {
		var err error
		errorFile, err = os.OpenFile(errorLog, os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0600)
		if err != nil {
			panic(err)
		}

	}

	defer errorFile.Close()

	if trafficLogEnabled == true {
		var err error

		trafficFile, err = os.OpenFile(trafficLog, os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0600)
		if err != nil {
			panic(err)
		}

	}

	defer trafficFile.Close()

	if criticalLogEnabled == true {
		var err error

		criticalFile, err = os.OpenFile(criticalLog, os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0600)
		if err != nil {
			panic(err)
		}

	}

	defer criticalFile.Close()

	for {
		select {
		case data := <-errorQueue:
			if errorLogEnabled == true {
				_, err := fmt.Fprint(errorFile, data, "\n")

				if err != nil {
					fmt.Println(err)
				}
			}
			break

		case data := <-trafficQueue:
			if trafficLogEnabled == true {
				_, err := fmt.Fprint(trafficFile, data, "\n")

				if err != nil {
					fmt.Println(err)
				}
			}
			break

		case data := <-criticalQueue:

			if criticalLogEnabled == true {
				_, err := fmt.Fprint(criticalFile, data, "\n")

				if err != nil {
					fmt.Println(err)
				}
			}
			break
		}
	}

}
