FROM golang:1.24-alpine AS builder

WORKDIR /app
COPY go.mod main.go ./
RUN go mod tidy && go mod download
RUN CGO_ENABLED=0 go build -o /stub-collector .

FROM alpine:3.20

COPY --from=builder /stub-collector /usr/local/bin/stub-collector

EXPOSE 4317

CMD ["/usr/local/bin/stub-collector"]
