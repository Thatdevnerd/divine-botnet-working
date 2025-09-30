package gologger

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
)

//Logger is used to log to a file
type Logger struct {
	filename string
	queue    chan interface{}
}

//New will create a new logger and service
func New(filename string, bufferSize int, options ...int) (Logger, error) {

	file, err := os.OpenFile(filename, os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0600)
	if err != nil {
		for _, val := range options {
			if val == SystemLogIfCreateFail {
				WritePrint(LogError, "Logger \""+filename+"\"", err)
			} else if PanicIfFileError == val {
				panic(err)
			}
		}
		return Logger{}, err
	}

	var queue = make(chan interface{}, bufferSize)

	go func() {
		defer file.Close()

		for {
			select {
			case data := <-queue:

				_, err := fmt.Fprint(file, data, "\n")

				if err != nil {
					WritePrint(LogError, "Logger \""+filename+"\"", err)
				}

				break
			}
		}
	}()

	logger := Logger{
		filename: filename,
		queue:    queue,
	}

	customLoggersMutex.Lock()
	customLoggers = append(customLoggers, logger)
	customLoggersMutex.Unlock()

	return logger, nil
}

//Write will queue the data to be written to disk
func (l *Logger) Write(data ...interface{}) {
	l.queue <- data
}

//WriteString will queue the data to be written to disk
func (l *Logger) WriteString(data ...interface{}) {

	var logData string
	for i := range data {

		if i == 0 {
			logData = fmt.Sprint(data[i])
			continue
		}

		logData += fmt.Sprint(" ", data[i])
	}

	l.queue <- logData
}

//WriteJSON will encode the data as json and write it to disk
func (l *Logger) WriteJSON(data interface{}) error {

	jsonData, err := json.Marshal(data)
	if err != nil {
		return err
	}

	l.queue <- string(jsonData)
	return nil
}

//WritePrint will print the data and send it to *Logger.Write()
func (l *Logger) WritePrint(data ...interface{}) {
	log.Println(l.filename, data)
	l.queue <- data
}
