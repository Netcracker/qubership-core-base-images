package main

import (
	"fmt"
	"os"
)

var (
	testContainerUrl = os.Getenv("TEST_URL")
)

func validateVersion() {
	version, err := os.ReadFile("/version")
	if err != nil {
		fmt.Printf("Failed to read /version: %v\n", err)
		os.Exit(1)
	}
	expected := "test\n"
	if string(version) != expected {
		fmt.Printf("Version validation failed: expected '%s', got '%s'\n", expected, string(version))
		os.Exit(1)
	}
	fmt.Println("Version validation passed")
}

func main() {
	defer func() {
		if r := recover(); r != nil {
			fmt.Printf("Recovered from test-service launch panic: %v\n", r)
			os.Exit(1)
		}
	}()
	validateVersion()
}
