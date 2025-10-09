package main

import (
	"crypto/x509"
	"encoding/pem"
	"fmt"
	"io/ioutil"
	"os"
	"strings"
)

var (
	secretsPath = os.Getenv("CERTIFICATE_FILE_LOCATION")
	trustStorePath = "/etc/ssl/certs"
	caCertPath = trustStorePath + "ca-certificates.crt"
)

func main() {
    info, err := os.Stat(secretsPath)
    if err != nil {
        fmt.Printf("Cannot access secrets folder: %v\n", err)
        return
    }
    if info.IsDir() {
        fmt.Printf("Secrets folder exists: %s\n", secretsPath)
        files, err := ioutil.ReadDir(secretsPath)
        if err != nil {
            fmt.Printf("Error reading secrets folder: %v\n", err)
        } else {
            fmt.Println("Secrets folder contents:")
            for _, file := range files {
                fmt.Println(" -", file.Name())
            }
        }
    } else {
        fmt.Printf("%s is not a directory\n", secretsPath)
    }

    fmt.Printf("Listing certificates in trust store: %s\n", trustStorePath)

    certFiles, err := ioutil.ReadDir(trustStorePath)
    if err != nil {
        fmt.Printf("Error reading trust store: %v\n", err)
        return
    }
    for _, cert := range certFiles {
        if !cert.IsDir() {
            fmt.Println(" -", cert.Name())
        }
    }

	checkCertsInTruststore()
}

func checkCertsInTruststore(){
    fmt.Println("Validate ca certificates were copied to store")
	data, err := ioutil.ReadFile(caCertPath)
    if err != nil {
        fmt.Printf("Error reading CA bundle: %v\n", err)
        return
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
            // skip invalid certificate
            continue
        }

        if strings.Contains(cert.Subject.CommonName, "testcerts.com") || 
           strings.Contains(fmt.Sprintf("%s", cert.Subject), "testcerts.com") {
            fmt.Printf("Subject: %s\n", cert.Subject.String())
            fmt.Printf("Expires on: %s\n", cert.NotAfter.Format("2006-01-02"))
            fmt.Println()
        }
    }
}