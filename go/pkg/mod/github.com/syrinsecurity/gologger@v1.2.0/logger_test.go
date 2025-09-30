package gologger

import (
	"testing"
)

func TestNewLoggerOptions(t *testing.T) {

	log, err := New("./log.txt", 200, PanicIfFileError)
	if err != nil {
		t.FailNow()
	}

	log.WriteString("test")
}

func TestNewLogger(t *testing.T) {

	log, err := New("./log.txt", 200)
	if err != nil {
		t.FailNow()
	}

	log.WriteString("test")
}

func TestGlobalLogger(t *testing.T) {
	go Service("./errors.log", "", "")
	Error.Write("error log")

	for {
		if QueueSize() == 0 {
			return
		}
	}
}
