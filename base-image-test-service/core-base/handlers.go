package main

import (
	"io"
	"net/http"

	"github.com/gofiber/fiber/v2"
)

type TestResponse struct {
	Path        string  `json:"path"`
	Method      string  `json:"method"`
	Message     string  `json:"message"`
}

func healthHandler(c *fiber.Ctx) error {
	logger.Info("Handle /health request")
	response := map[string]string{
		"status": "OK",
	}
	return c.Status(http.StatusOK).JSON(response)
}

func certificateHandler(c *fiber.Ctx) error {
	logger.Info("Handle /certificate request")
	return c.SendFile(serverCertPath)
}

func callFromServiceHandler(c *fiber.Ctx) error {
	logger.Info("Handle /call_from_service request")
    resp, err := http.Get(testContainerUrl)
    if err != nil {
        logger.Error("Failed to call service: "+err.Error(), http.StatusInternalServerError)
        return err
    }
    defer resp.Body.Close()

    body, err := io.ReadAll(resp.Body)
    if err != nil {
       logger.Error("Failed to read response: "+err.Error(), http.StatusInternalServerError)
        return err
    }

	return RespondWithJson(c, resp.StatusCode, body)
}

func RespondWithJson(c *fiber.Ctx, code int, payload interface{}) error {
	return c.Status(code).JSON(payload)
}