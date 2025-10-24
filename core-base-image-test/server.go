package main

import (
	"fmt"
	"net/http"
	"os"
)

var (
	testContainerUrl = os.Getenv("TEST_URL")
)

func main() {
	defer func() {
		if r := recover(); r != nil {
			fmt.Printf("Recovered from test-service launch panic: %v", r)
		}
	}()
	
	fmt.Println("Handle /call_from_service request")
    resp, err := http.Get(testContainerUrl)
    if err != nil {
        fmt.Printf("Failed to call service: "+err.Error(), http.StatusInternalServerError)
    }

	fmt.Printf("Resonsed with: %d", resp.StatusCode)
}