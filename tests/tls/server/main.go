package main

import (
	"log"
	"net/http"
	"os"
)

func main() {
	certFile := os.Getenv("TLS_CERT")
	if certFile == "" {
		log.Fatal("Missing TLS_CERT environment variable")
	}
	keyFile := os.Getenv("TLS_KEY")
	if keyFile == "" {
		log.Fatal("Missing TLS_KEY environment variable")
	}
	addr := os.Getenv("TLS_ADDR")
	if addr == "" {
		log.Fatal("Missing TLS_ADDR environment variable")
	}

	http.HandleFunc("/", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	log.Printf("TLS server listening on %s", addr)
	if err := http.ListenAndServeTLS(addr, certFile, keyFile, nil); err != nil {
		log.Fatal(err)
	}
}
