package main

import (
	"crypto/tls"
	"fmt"
	"net"
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

    hostname := "host.docker.internal"
    addrs, err := net.LookupHost(hostname)
    if err != nil {
        fmt.Printf("Failed to resolve %s: %v\n", hostname, err)
        return
    }

    fmt.Printf("Resolved addresses for %s:\n", hostname)
    for _, addr := range addrs {
        fmt.Println(addr)
    }

	tr := &http.Transport{
    	TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
    }
    client := &http.Client{Transport: tr}

    resp, err := client.Get(testContainerUrl)
    if err != nil {
        fmt.Printf("Failed to call service: %v\n", err)
        os.Exit(1)
    } 
    defer resp.Body.Close()

    fmt.Printf("Responded with: %d\n", resp.StatusCode)
}