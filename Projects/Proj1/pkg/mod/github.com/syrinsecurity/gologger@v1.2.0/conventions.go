package gologger

import (
	"time"
)

//SetNameConventionMonthYear will automatically configure the logger to use this convention, it will set the convention function and the update period
func SetNameConventionMonthYear(logger *CustomLogger) {
	//Check every 24 hours if a month as elapsed
	logger.ConventionUpdate = time.Hour * 24

	logger.NameingConvention = func() string {
		return time.Now().Format("Jan-2006")
	}
}

//SetNameConventionYear will automatically configure the logger to use this convention, it will set the convention function and the update period
func SetNameConventionYear(logger *CustomLogger) {
	//Check every 24 hours if a month as elapsed
	logger.ConventionUpdate = time.Hour * 24

	logger.NameingConvention = func() string {
		return time.Now().Format("2006")
	}
}

//SetNameConventionDayMonthYear will automatically configure the logger to use this convention, it will set the convention function and the update period
func SetNameConventionDayMonthYear(logger *CustomLogger) {
	//Check every minute to make sure it stays up to date
	logger.ConventionUpdate = time.Minute

	logger.NameingConvention = func() string {
		return time.Now().Format("Monday-Jan-2006")
	}
}
