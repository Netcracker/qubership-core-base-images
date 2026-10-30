FROM golang:1.26.3-alpine AS builder

WORKDIR /app
COPY go.mod go.sum main.go ./
RUN CGO_ENABLED=0 go build -o /stub-collector .

FROM alpine:3.24@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a

COPY --from=builder /stub-collector /usr/local/bin/stub-collector

EXPOSE 4317

CMD ["/usr/local/bin/stub-collector"]
