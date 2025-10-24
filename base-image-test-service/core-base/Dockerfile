FROM golang:1.25 AS build

COPY ./* /app/

WORKDIR /app

RUN go build -o check_env 

FROM ghcr.io/netcracker/qubership/core-base:test

COPY --chown=10001:0 --chmod=555 --from=build app/check_env /app/check_env
COPY --chown=10001:0 --chmod=555 server.key /app/server.key

WORKDIR /app

USER 10001:10001

CMD ["./check_env"]
