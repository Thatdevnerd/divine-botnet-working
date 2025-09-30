package gologger

//QueueSize returns the current size of all queues
func QueueSize() int {

	var count int
	for _, logger := range customLoggers {
		count += len(logger.queue)
	}

	count = count + len(errorQueue) + len(criticalQueue) + len(trafficQueue)

	return count
}
