package main

import (
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGTERM)
	fmt.Println("Go app: started")
	select {
	case <-time.After(5 * time.Second):
		fmt.Println("Go app: delayed message")
	case <-sigs:
		fmt.Println("Go app: captured SIGTERM")
		os.Exit(143)
	}
	<-sigs
	fmt.Println("Go app: captured SIGTERM")
	os.Exit(143)
}
