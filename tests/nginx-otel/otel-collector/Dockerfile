FROM golang:1.27.4-alpine@sha256:0a5f7fe796599ff487605987432e7619ae45beeb2fba4c2ce0b907879932aebf AS builder

WORKDIR /app
COPY go.mod go.sum main.go ./
RUN CGO_ENABLED=0 go build -o /stub-collector .

FROM alpine:3.24@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf

COPY --from=builder /stub-collector /usr/local/bin/stub-collector

EXPOSE 4317

CMD ["/usr/local/bin/stub-collector"]
