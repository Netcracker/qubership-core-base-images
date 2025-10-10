package main

import (
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"strings"
)

var (
	secretsPath = os.Getenv("CERTIFICATE_FILE_LOCATION")
	trustStorePath = "/etc/ssl/certs/"
	caCertPath = trustStorePath + "ca-certificates.crt"
)

func main() {
    info, err := os.Stat(secretsPath)
    if err != nil {
        log.Printf("Cannot access secrets folder: %v\n", err)
        return
    }
    if info.IsDir() {
        log.Printf("Secrets folder exists: %s\n", secretsPath)
        files, err := ioutil.ReadDir(secretsPath)
        if err != nil {
            log.Printf("Error reading secrets folder: %v\n", err)
        } else {
            log.Println("Secrets folder contents:")
            for _, file := range files {
                log.Println(" -", file.Name())
            }
        }
    } else {
        log.Printf("%s is not a directory\n", secretsPath)
    }

    log.Printf("Listing certificates in trust store: %s\n", trustStorePath)

    certFiles, err := ioutil.ReadDir(trustStorePath)
    if err != nil {
        log.Printf("Error reading trust store: %v\n", err)
        return
    }
    for _, cert := range certFiles {
        if !cert.IsDir() {
            log.Printf(" - %s", cert.Name())
        }
    }

	checkCertsInTruststore()
}

func checkCertsInTruststore(){
    log.Println("Validate ca certificates were copied to store")
    data, err := ioutil.ReadFile(caCertPath)
    if err != nil {
        log.Fatalf("Error reading CA bundle: %v", err)
    }

    var block *pem.Block
    rest := data

    for {
        block, rest = pem.Decode(rest)
        if block == nil {
            break
        }

        if block.Type != "CERTIFICATE" {
            continue
        }

        cert, err := x509.ParseCertificate(block.Bytes)
        if err != nil {
            log.Printf("Error parsing certificate: %v", err)
            continue
        }

        if strings.Contains(cert.Subject.CommonName, "testcerts.com") || 
           strings.Contains(fmt.Sprintf("%s", cert.Subject), "testcerts.com") {
            log.Printf("Subject: %s\n", cert.Subject.String())
            log.Printf("Expires on: %s\n", cert.NotAfter.Format("2006-01-02"))
        }
    }
}