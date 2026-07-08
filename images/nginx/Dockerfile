# despite this argument user for runtime docker part, docker buildx failed to builde image if move
# this declaration anywhere else
ARG BASE_IMAGE=ghcr.io/netcracker/qubership-core-base:latest@sha256:b77f160cfd406124b3f1be223e82b21e742d5533638c64409e5992342587304a

FROM alpine:3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b AS builder

RUN apk add --no-cache \
    build-base linux-headers \
    cmake pkgconfig \
    git ca-certificates \
    curl-dev pcre-dev zlib-dev protobuf-dev \
    c-ares-dev re2-dev libstdc++ luajit-dev

WORKDIR /usr/src

# renovate: datasource=github-tags depName=nginx/nginx
ARG NGINX_VERSION=release-1.28.3
# renovate: datasource=github-tags depName=vision5/ngx_devel_kit
ARG NGX_DEVEL_KIT_VERSION=v0.3.4
# renovate: datasource=github-tags depName=openresty/lua-nginx-module
ARG LUA_NGINX_MODULE_VERSION=v0.10.28
# renovate: datasource=github-tags depName=google/ngx_brotli
ARG NGX_BROTLI_VERSION=master
# renovate: datasource=github-tags depName=openresty/headers-more-nginx-module
ARG HEADERS_MORE_VERSION=v0.39
# renovate: datasource=github-tags depName=openresty/lua-resty-lrucache
ARG LUA_RESTY_LRUCACHE_VERSION=v0.15
# renovate: datasource=github-tags depName=openresty/lua-resty-core
ARG LUA_RESTY_CORE_VERSION=v0.1.31
# renovate: datasource=git-refs depName=https://github.com/nginxinc/nginx-otel.git currentValue=main
ARG NGINX_OTEL_COMMIT=6eb28d7452f6ce2e009cc25470aec091826503b3

RUN git clone --depth 1 --branch ${NGINX_VERSION} https://github.com/nginx/nginx.git && \
    git clone --depth 1 --branch ${NGX_DEVEL_KIT_VERSION} https://github.com/vision5/ngx_devel_kit.git && \
    git clone --depth 1 --branch ${LUA_NGINX_MODULE_VERSION} https://github.com/openresty/lua-nginx-module.git && \
    git clone --depth 1 --recurse-submodules --shallow-submodules --branch ${NGX_BROTLI_VERSION} https://github.com/google/ngx_brotli.git && \
    git clone --depth 1 --branch ${HEADERS_MORE_VERSION} https://github.com/openresty/headers-more-nginx-module.git

RUN cd ngx_brotli/deps/brotli && mkdir -p out && cd out && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=./installed .. && \
    cmake --build . -j$(nproc) --config Release --target brotlienc

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
        --add-module=/usr/src/headers-more-nginx-module \
    " && \
    export LUAJIT_LIB=/usr/lib && \
    export LUAJIT_INC=/usr/include/luajit-2.1 && \
    cd nginx/ && auto/configure $CONFIG

RUN cd nginx/ && make -j$(nproc) && make install

RUN git clone https://github.com/nginxinc/nginx-otel.git && \
    cd nginx-otel && \
    git checkout ${NGINX_OTEL_COMMIT} && \
    mkdir build && cd build && \
    cmake -DNGX_OTEL_NGINX_BUILD_DIR=/usr/src/nginx/objs \
      -DCMAKE_CXX_FLAGS="-D_LARGEFILE64_SOURCE -Wno-attributes -Wno-trigraphs -Wno-deprecated-declarations -Wno-return-type" \
      .. && \
    make -j$(nproc)

RUN mkdir -p lua && \
    git clone --depth 1 --branch ${LUA_RESTY_LRUCACHE_VERSION} https://github.com/openresty/lua-resty-lrucache.git /tmp/lua-cache/ && \
    cp -fR /tmp/lua-cache/* lua/ && \
    git clone --depth 1 --branch ${LUA_RESTY_CORE_VERSION} https://github.com/openresty/lua-resty-core.git /tmp/lua-core/ && \
    cp -fR /tmp/lua-core/* lua/ && \
    find lua/ -maxdepth 1 -mindepth 1 ! -name 'lib' -exec rm -rf -- {} +

# ---- Runtime stage ----
FROM ${BASE_IMAGE}
LABEL maintainer="qubership"

ARG BASE_IMAGE_TAG=qubership-nginx-base:unknown
ARG UID=appuser
ARG GID=root

ENV LUA_LIB_ROOT=/usr/local/lib/lua
ENV LUA_PATH=$LUA_LIB_ROOT/?.lua

# switch to root for build phase
USER root
RUN echo $BASE_IMAGE_TAG > /etc/base-image-release

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx/ /etc/nginx/
COPY --from=builder /usr/lib/nginx/modules/ /usr/lib/nginx/modules/
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/share/luajit* /usr/local/share/
COPY --from=builder /usr/src/lua/lib/ /usr/local/lib/lua/
COPY --from=builder /usr/local/lib/libopentelemetry_proto*.so /usr/local/lib/
COPY --from=builder \
    /usr/lib/libabsl_*.so* \
    /usr/lib/libupb_*.so* \
    /usr/lib/libgrpc*.so* \
    /usr/lib/libgpr.so* \
    /usr/lib/libprotobuf.so* \
    /usr/lib/libstdc*.so* \
    /usr/lib/libpcre.so* \
    /usr/lib/libssl.so* \
    /usr/lib/libcrypto.so* \
    /usr/lib/libz.so* \
    /usr/lib/libgcc_s.so* \
    /usr/lib/libre2.so* \
    /usr/lib/libcares.so* \
    /usr/lib/libaddress_sorting.so* \
    /usr/lib/libutf8_validity.so* \
    /usr/lib/libutf8_range_lib.so* \
    /usr/lib/libicuuc.so* \
    /usr/lib/libicudata.so* \
    /usr/lib/libbrotli*.so* \
    /usr/lib/libluajit*.so* \
    /usr/lib/
COPY --from=builder \
    /usr/src/nginx-otel/build/ngx_otel_module.so \
    /usr/lib/nginx/modules/

RUN rm -rf /etc/nginx/modules \
    && ln -s /usr/lib/nginx/modules /etc/nginx/modules \
    && mkdir -p /var/log/nginx \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && touch /run/nginx.pid \
    && chown ${UID}:${GID} /run /run/nginx.pid

VOLUME /var/log
VOLUME /var/cache/nginx/client_temp
VOLUME /var/cache/nginx/proxy_temp
VOLUME /var/cache/nginx/fastcgi_temp
VOLUME /var/cache/nginx/uwsgi_temp
VOLUME /var/cache/nginx/scgi_temp

USER ${UID}