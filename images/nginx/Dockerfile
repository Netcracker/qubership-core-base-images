FROM alpine:3.23 AS builder

RUN apk add git gcc make
RUN apk add make cmake gcc g++ git
RUN apk add build-base linux-headers alpine-sdk
RUN apk add pkgconfig autoconf gnupg libtool
RUN apk add curl ca-certificates
RUN apk add curl-dev pcre-dev zlib-dev protobuf-dev
RUN apk add c-ares-dev re2-dev
RUN apk add libstdc++
RUN apk add luajit-dev

WORKDIR /usr/src

RUN git clone https://github.com/nginx/nginx.git
RUN git clone --depth 1 --branch v0.3.3 https://github.com/vision5/ngx_devel_kit.git
RUN git clone --depth 1 --branch v0.10.26 https://github.com/openresty/lua-nginx-module.git
RUN git clone --recurse-submodules https://github.com/google/ngx_brotli.git
RUN cd ngx_brotli/deps/brotli && mkdir -p out && cd out && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=./installed .. && \
    cmake --build . -j6 --config Release --target brotlienc
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
        --user=appuser \
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
        --add-module=/usr/src/ngx_devel_kit \
        --add-module=/usr/src/lua-nginx-module \
        --add-dynamic-module=/usr/src/ngx_brotli \
    " && \
    export LUAJIT_LIB=/usr/lib && \
    export LUAJIT_INC=/usr/include/luajit-2.1 && \
    cd nginx/ && auto/configure $CONFIG

RUN cd nginx/ && make -j6 && make install

# lua-nginx-module loads lua-resty-core by default; ship OpenResty libs under default lua_package_path
RUN mkdir -p /usr/local/share/lua/5.1 && \
    git clone --depth 1 --branch v0.13 https://github.com/openresty/lua-resty-lrucache.git /tmp/lua-resty-lrucache && \
    cp -r /tmp/lua-resty-lrucache/lib/resty /usr/local/share/lua/5.1/ && \
    rm -rf /tmp/lua-resty-lrucache && \
    git clone --depth 1 --branch v0.1.28 https://github.com/openresty/lua-resty-core.git /tmp/lua-resty-core && \
    cp -r /tmp/lua-resty-core/lib/resty/* /usr/local/share/lua/5.1/resty/ && \
    rm -rf /tmp/lua-resty-core

RUN git clone https://github.com/nginxinc/nginx-otel.git
RUN cd nginx-otel && \
    mkdir build && \
    cd build && \
    cmake -DNGX_OTEL_NGINX_BUILD_DIR=/usr/src/nginx/objs \
      -DCMAKE_CXX_FLAGS="-D_LARGEFILE64_SOURCE -Wno-attributes -Wno-trigraphs -Wno-deprecated-declarations -Wno-return-type" \
      ..
RUN cd nginx-otel/build && make -j6

RUN mkdir -p /usr/lib/nginx/modules/ && \
    mv /usr/src/nginx-otel/build/ngx_otel_module.so /usr/lib/nginx/modules/

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