package main

import (
	"log"
	"net/http"
	"os"
)

func main() {
	certFile := os.Getenv("TLS_CERT")
	if certFile == "" {
		certFile = "/certs/server.crt"
	}
	keyFile := os.Getenv("TLS_KEY")
	if keyFile == "" {
		keyFile = "/certs/server.key"
	}
	addr := os.Getenv("TLS_ADDR")
	if addr == "" {
		addr = ":8443"
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
