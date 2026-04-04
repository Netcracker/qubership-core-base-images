FROM alpine:3.23 AS builder

RUN apk add git gcc make
RUN apk add make cmake gcc g++ git
RUN apk add build-base linux-headers alpine-sdk
RUN apk add pkgconfig autoconf gnupg libtool
RUN apk add curl ca-certificates
RUN apk add curl-dev pcre-dev zlib-dev protobuf-dev
RUN apk add c-ares-dev re2-dev
RUN apk add libstdc++

WORKDIR /usr/src

RUN git clone https://github.com/nginx/nginx.git
RUN CONFIG="\
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_v2_module \
        --with-http_ssl_module \
        --with-ipv6 \
        --with-ld-opt="-Wl,-rpath,/usr/lib" \
        --with-http_auth_request_module \
        --with-http_sub_module \
        --with-http_stub_status_module \
        --with-compat \
    " && \
    cd nginx/ && auto/configure $CONFIG

RUN cd nginx/ && make -j6 && make install

RUN git clone https://github.com/nginxinc/nginx-otel.git
RUN cd nginx-otel && \
    mkdir build && \
    cd build && \
    cmake -DNGX_OTEL_NGINX_BUILD_DIR=/usr/src/nginx/objs \
      -DCMAKE_CXX_FLAGS="-D_LARGEFILE64_SOURCE -Wno-attributes -Wno-trigraphs -Wno-deprecated-declarations -Wno-return-type" \
      ..
RUN cd nginx-otel/build && make -j6

RUN mkdir -p /usr/lib/nginx/modules/ && mv /usr/src/nginx-otel/build/ngx_otel_module.so /usr/lib/nginx/modules/

ARG UID=10001
ARG GID=root

RUN rm -rf /etc/nginx/modules \
    && ln -s /usr/lib/nginx/modules /etc/nginx/modules \
    && mkdir -p /var/log/nginx \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && touch /run/nginx.pid \
    && chown ${UID}:${GUID} /run /run/nginx.pid

VOLUME /var/log
VOLUME /var/cache/nginx/client_temp
VOLUME /var/cache/nginx/proxy_temp
VOLUME /var/cache/nginx/fastcgi_temp
VOLUME /var/cache/nginx/uwsgi_temp
VOLUME /var/cache/nginx/scgi_temp