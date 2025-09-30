# Gologger

![Go report card](https://goreportcard.com/badge/github.com/syrinsecurity/gologger)
[![Build Status](https://travis-ci.org/syrinsecurity/gologger.svg?branch=master)](https://travis-ci.org/syrinsecurity/gologger)
[![GoDoc](https://godoc.org/github.com/syrinsecurity/gologger?status.svg)](https://godoc.org/github.com/syrinsecurity/gologger)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/syrinsecurity/gologger/graphs/commit-activity)
[![License](https://img.shields.io/github/license/syrinsecurity/gologger.svg)](https://github.com/syrinsecurity/gologger/blob/master/LICENSE)
[![GitHub release](https://img.shields.io/github/release/syrinsecurity/gologger.svg)](https://GitHub.com/syrinsecurity/gologger/releases/)
[![GitHub issues](https://img.shields.io/github/issues/syrinsecurity/gologger.svg)](https://GitHub.com/syrinsecurity/gologger/issues/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)


<img align="right" src="./.github/images/logo.png">

Gologger is a concurrent **thread safe** logging system which writes to the filesystem. Gologger utilises a service worker model with buffered channels/queues.
No need to worry about leaking file descriptors as Gologger only opens one descriptor per file.

- Non blocking, uses a queue whith a service worker to proccess logs.
- Thread/Concurrent **safe**.
- Supports any data type! Supports interface{} type.
- Use logger just like fmt, provide as many arguments as you need.
- Advanced features such as naming conventions e.g. logs-Jul-2020.txt

## Install

> go get github.com/syrinsecurity/gologger

# Basic Examples

Custom loggers

```go
func main() {

	/*
	"./file.log" is where the logs will be written to. If this file does not exist it will be created.

	"200" is the buffer size of the channel
	*/
	logger, err := gologger.New("./file.log", 200)
	if err != nil {
		panic(err)
	}

	logger.WriteString("log any data you want.")
	logger.WriteString("This is a interface so you can use any type you like.", "UserID:", 9039832898, "Timestamp:", time.Now().Unix())
}
```

```go
package main

import "github.com/syrinsecurity/gologger"

var (
	logger, _ = gologger.New("./file.log", 200)
)

func main() {
	logger.Write("data", 123, 345)
}
```

Use the built in loggers for fast setup

```go
package main

import "github.com/syrinsecurity/gologger"

func main() {

	//Start the service worker
	//Leave the path blank for loggers you do not want to use
	go gologger.Service("./error.log", "", "")

	gologger.Write(gologger.LogError, "error data")

	//Quick logger syntax
	gologger.Error.Write(errors.New("example error"))
}
```

# Advanced Usage

```go
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
```

### Naming conventions

- SetNameConventionMonthYear()		Jan-2006
- SetNameConventionYear()		2006
- SetNameConventionDayMonthYear()	Monday-Jan-2006

You can create your own naming conventions by setting ``logger.NameingConvention`` to equal a func() string of your choosing.
**Note** By default the naming convention returns a empty string. If you do not want to use a naming convention you can just not modify the default.

### Settings

- LineTerminator - Appends a suffix to the end of the log, default is "\n"
- ValueSeperator - Is the value inbetween each value insert when you use multipule values on the write method, default is " "
- ConventionUpdate - Determins how often the filename should be checked for new changes
- Extention - This is your file extention what is appened after the name convention
- Path - This is where you want to store the log file, it also includes the start of the filename

### Methods & Callbacks

- Close() - This will shutdown the service worker
- ConventionUpdated(oldFile string, newFile string) - This call back is returned when the naming convention has changed thus a new log file has been created.
	- You could use this callback to backup the "old" log file.

Get the size of all basic queues:

> gologger.QueueSize()

For more examples look at https://github.com/syrinsecurity/gologger/tree/master/examples
