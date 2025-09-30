package gologger

import (
	"log"
	"sync"
)

var (
	errorQueue    = make(chan []interface{}, 30000)
	trafficQueue  = make(chan []interface{}, 30000)
	criticalQueue = make(chan []interface{}, 30000)

	customLoggers      []Logger
	customLoggersMutex sync.Mutex
)

//Write will sort the event into the correct queue then procress the action as write to disk
func Write(logType int, data ...interface{}) {

	switch logType {
	case LogError:
		errorQueue <- data
		break

	case LogTraffic:
		trafficQueue <- data
		break

	case LogCritical:
		criticalQueue <- data
		break
	default:

	}
}

//WritePrint will print the data and send it to Systemlog.Write()
func WritePrint(logType int, data ...interface{}) {
	log.Println(logType, data)
	Write(logType, data)
}

//Write will sort the event into the correct queue then procress the action as write to disk
func (l LogType) Write(data ...interface{}) {
	switch l.int {
	case LogError:
		errorQueue <- data
		break

	case LogTraffic:
		trafficQueue <- data
		break

	case LogCritical:
		criticalQueue <- data
		break
	default:

	}
}

//WritePrint will print the data and send it to Systemlog.Write()
func (l LogType) WritePrint(data ...interface{}) {
	log.Println(l.int, data)
	l.Write(data)
}
