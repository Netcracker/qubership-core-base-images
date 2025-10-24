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
            fmt.Printf("Recovered from test-service launch panic: %v\n", r)
			os.Exit(1)
        }
    }()

    fmt.Println("Handle /call_from_service request")
    resp, err := http.Get(testContainerUrl)
    if err != nil && resp.StatusCode !=200 {
        fmt.Printf("Failed to call service: %v\n", err)
        os.Exit(1)
    } 
    defer resp.Body.Close()

    fmt.Printf("Responded with: %d\n", resp.StatusCode)
}