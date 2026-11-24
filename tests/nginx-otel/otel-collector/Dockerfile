FROM golang:1.27.4-alpine@sha256:70bd7ddea8b6cbe5d6943cde279d6b67feb10cc924fb9100d1d8757c1575b280 AS builder

WORKDIR /app
COPY go.mod go.sum main.go ./
RUN CGO_ENABLED=0 go build -o /stub-collector .

FROM alpine:3.24@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf

COPY --from=builder /stub-collector /usr/local/bin/stub-collector

EXPOSE 4317

CMD ["/usr/local/bin/stub-collector"]
