ARG IMAGE=alpine:3.23
FROM golang:1.26.1-alpine AS builder

WORKDIR /app
COPY go.mod main.go ./
RUN CGO_ENABLED=0 go build -o /tls-server .

FROM ${IMAGE}

COPY --from=builder /tls-server /app/tls-server

EXPOSE 8443

CMD ["/app/tls-server"]
