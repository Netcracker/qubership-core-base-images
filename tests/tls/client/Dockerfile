ARG IMAGE=alpine:3.23
FROM golang:1.26.1-alpine AS builder

WORKDIR /app
COPY go.mod main.go ./
RUN CGO_ENABLED=0 go build -o /tls-client .

FROM ${IMAGE}

COPY --from=builder /tls-client /app/tls-client

CMD ["/app/tls-client"]
