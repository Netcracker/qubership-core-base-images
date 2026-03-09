package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	server := os.Getenv("TLS_SERVER")
	if server == "" {
		server = "tls-server:8443"
	}
	url := "https://" + server + "/"

	resp, err := http.Get(url)
	if err != nil {
		log.Fatalf("TLS connection failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		log.Fatalf("unexpected status: %s", resp.Status)
	}

	fmt.Println("TLS connection OK")
}
