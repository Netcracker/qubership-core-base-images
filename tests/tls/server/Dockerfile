ARG IMAGE
FROM golang:1.27.4-alpine@sha256:0a5f7fe796599ff487605987432e7619ae45beeb2fba4c2ce0b907879932aebf AS builder

WORKDIR /app
COPY go.mod main.go ./
RUN CGO_ENABLED=0 go build -o /tls-server .

FROM ${IMAGE}

COPY --from=builder /tls-server /app/tls-server

EXPOSE 8443

CMD ["/app/tls-server"]
