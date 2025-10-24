package main

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"net/http"
	"os"

	"github.com/gofiber/fiber/v2"
	"github.com/netcracker/qubership-core-lib-go/v3/logging"
)

var (
	secretsPath = os.Getenv("CERTIFICATE_FILE_LOCATION") + "/"
	serverKey = os.Getenv("SERVER_KEY_NAME")

	serverCertPath = secretsPath + serverKey + ".crt"
	certPKey = "/app/" + serverKey + ".key"

	testContainerUrl = os.Getenv("TEST_URL")

	ctx    = context.Background()
	logger logging.Logger
)

func init() {
	logger = logging.GetLogger("main")
}

func runTestService() {
	logger.InfoC(ctx, "Start service...")
	app := fiber.New()
	app.Get("/health", healthHandler)
	app.Get("/certificate", certificateHandler)
	app.Get("/call_from_service", callFromServiceHandler)

	httpPort := ":8080"
	go func() {
		err := app.Listen(httpPort)
		if err != nil {
			logger.Infof("Error during start http server: %+v", err.Error())
		}
	}()
	// load server certificate
	serverCertificate, err := tls.LoadX509KeyPair(serverCertPath, certPKey)
	if err != nil {
		logger.Panic("Cannot load TLS key pair from cert file=%s and key file=%s: %+v", serverCertPath, certPKey, err)
	}

	rootCAs, _ := x509.SystemCertPool()
	if rootCAs == nil {
		rootCAs = x509.NewCertPool()
	}

	tlsConfig := &tls.Config{
		RootCAs:    rootCAs,
		MinVersion: tls.VersionTLS12,
		ClientAuth: tls.VerifyClientCertIfGiven,
		ClientCAs:  rootCAs,
		Certificates: []tls.Certificate{
			serverCertificate,
		},
	}

	httpsBind := os.Getenv("HTTPS_SERVER_BIND")
	if httpsBind == "" {
		httpsBind = ":8443"
	}

	server := &http.Server{
		Addr:      httpsBind,
		TLSConfig: tlsConfig,
		Handler: http.HandlerFunc(func(res http.ResponseWriter, req *http.Request) {
			fmt.Fprint(res, "OK")
		}),
	}

	logger.Info("Start https server on %s", httpsBind)
	logger.Panic("can not start server: ", server.ListenAndServeTLS(serverCertPath, certPKey))
}

func main() {
	defer func() {
		if r := recover(); r != nil {
			logger.ErrorC(ctx, "Recovered from test-service launch panic: %v", r)
		}
	}()
	go runTestService()
	select {}
}