ARG IMAGE
FROM golang:1.27.3-alpine@sha256:fa3d596898d9f126af7c01d14ee7597bab3f39cccf392ef36b69fe77cd681f18 AS builder

WORKDIR /app
COPY go.mod main.go ./
RUN CGO_ENABLED=0 go build -o /tls-client .

FROM ${IMAGE}

COPY --from=builder /tls-client /app/tls-client

CMD ["/app/tls-client"]
