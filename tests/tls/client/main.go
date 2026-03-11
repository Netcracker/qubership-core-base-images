package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	url := os.Getenv("URL")
	if url == "" {
		log.Fatalf("Missing mandatory URL environment variable")
	}

	log.Printf("Connecting to %s", url)
	resp, err := http.Get(url)
	if err != nil {
		log.Fatalf("TLS connection failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		log.Fatalf("unexpected status: %s", resp.Status)
	}

	fmt.Println("Connection OK")
}
