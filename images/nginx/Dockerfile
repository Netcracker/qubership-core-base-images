# despite this argument user for runtime docker part, docker buildx failed to builde image if move
# thid declaration anywhere else
ARG BASE_IMAGE=ghcr.io/netcracker/qubership-core-base:latest

FROM alpine:3.23 AS builder

ENV NGINX_VERSION=1.28.2
ENV LUA_LIB_ROOT=/usr/local/lib/lua
ENV LUA_SHARE_ROOT=/usr/local/share/lua/5.4
ENV LUA_PATH=$LUA_LIB_ROOT/?.lua;$LUA_SHARE_ROOT/?.lua;

ARG BROTLI_VERSION="1.0.0rc"
ARG LUAJIT_VERSION="2.1-20251030"
ARG LUA_NGINX_MODULE_VERSION="0.10.29"
ARG LUA_RESTY_WEBSOCKET_VERSION="0.13"
ARG NGINX_HEADERS_MORE_NGINX_MODULE_VERSION="0.39"
ARG NGINX_LUA_PROMETHEUS_TAG="0.20240525"
ARG NGINX_LUA_RESTY_CJSON_VERSION="2.1.0.15"
ARG NGINX_LUA_RESTY_CORE_VERSION="0.1.32R1"
ARG NGINX_LUA_RESTY_LRUCASHE_VERSION="0.15"
ARG NGX_DEVEL_KIT_VERSION="0.3.4"
ARG NGX_HTTP_SUBSTITUTIONS_FILTER_MODULE_VERSION="0.6.4"
ARG OPENRESTY_VERSION="1.29.2.1"
ARG OTEL_CPP_VERSION="1.11.0"
ARG OTEL_PROTO_VERSION="1.1.0"
ARG OTEL_WEBSERVER_VERSION="1.1.0"

RUN apk add --no-cache \
        abseil-cpp \
        abseil-cpp-vlog-config-internal \
        c-ares-dev \
        cmake \
        curl \
        curl-dev \
        g++ \
        gcc \
        gettext \
        git \
        grpc-cpp \
        grpc-dev \
        libc-dev \
        libcrypto3 \
        libcurl \
        libpsl \
        libssl3 \
        linux-headers \
        make \
        openssl-dev \
        patch \
        pcre-dev \
        perl-dev \
        protobuf-dev \
        re2-dev \
        zlib-dev \
    && export LUAJIT_LIB=/usr/local/lib \
    && export LUAJIT_INC=/usr/local/include/luajit-2.1 \
    && export LUA_INCLUDE_DIR=/usr/local/include/luajit-2.1 \
    && echo "[BUILD_PHASE] Build binaries from the published packaging sources" \
    && CONFIG="\
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
        --add-module=../ngx_http_substitutions_filter_module-$NGX_HTTP_SUBSTITUTIONS_FILTER_MODULE_VERSION \
        --add-module=../ngx_devel_kit-$NGX_DEVEL_KIT_VERSION \
        --add-module=../lua-nginx-module-$LUA_NGINX_MODULE_VERSION \
        --add-module=../headers-more-nginx-module-$NGINX_HEADERS_MORE_NGINX_MODULE_VERSION \
        --add-dynamic-module=/usr/src/ngx_brotli-$BROTLI_VERSION \
    "\
    && mkdir -p /usr/src \
	&& curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
    && curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc -o nginx.tar.gz.asc \
    && curl -fSL https://github.com/vision5/ngx_devel_kit/archive/v$NGX_DEVEL_KIT_VERSION.tar.gz -o ndk.tar.gz \
    && curl -fSL https://github.com/openresty/lua-nginx-module/archive/v$LUA_NGINX_MODULE_VERSION.tar.gz -o lua-nginx-module.tar.gz \
    && curl -fSL https://openresty.org/download/openresty-$OPENRESTY_VERSION.tar.gz -o openresty-$OPENRESTY_VERSION.tar.gz \
    && curl -fSL https://github.com/yaoweibin/ngx_http_substitutions_filter_module/archive/v$NGX_HTTP_SUBSTITUTIONS_FILTER_MODULE_VERSION.tar.gz -o ngx_http_substitutions_filter_module.tar.gz \
    && curl -fSL https://github.com/open-telemetry/opentelemetry-cpp/archive/v$OTEL_CPP_VERSION.tar.gz -o opentelemetry-cpp.tar.gz \
    && curl -fSL https://github.com/open-telemetry/opentelemetry-cpp-contrib/archive/refs/tags/webserver/v$OTEL_WEBSERVER_VERSION.tar.gz -o opentelemetry-cpp-contrib-webserver.tar.gz \
    && curl -fSL https://github.com/open-telemetry/opentelemetry-proto/archive/v$OTEL_PROTO_VERSION.tar.gz -o opentelemetry-proto.tar.gz \
    && curl -fSL https://github.com/knyar/nginx-lua-prometheus/archive/$NGINX_LUA_PROMETHEUS_TAG.tar.gz -o nginx-lua-prometheus.tar.gz \
    && curl -fSL https://github.com/google/ngx_brotli/archive/refs/tags/v$BROTLI_VERSION.tar.gz -o ngx_brotli.tar.gz \
    && curl -fSL https://github.com/openresty/luajit2/archive/v$LUAJIT_VERSION.tar.gz -o luajit.tar.gz \
    && tar -zxC /usr/src -f luajit.tar.gz \
	&& tar -zxC /usr/src -f nginx.tar.gz \
    && echo "[BUILD_PHASE] applying nginx delayed_posted_events patch" \
    && curl -fSL https://raw.githubusercontent.com/openresty/openresty/v$OPENRESTY_VERSION/patches/nginx/1.27.1/nginx-1.27.1-delayed_posted_events.patch -o /usr/src/delayed_posted_events.patch \
    && ( cd /usr/src/nginx-$NGINX_VERSION && patch -p1 < /usr/src/delayed_posted_events.patch ) \
    && echo "[BUILD_PHASE] patch applied successfully" \
	&& tar -zxC /usr/src -f ngx_http_substitutions_filter_module.tar.gz \
	&& tar -zxC /usr/src -f ndk.tar.gz \
	&& tar -zxC /usr/src -f lua-nginx-module.tar.gz \
    && tar -zxC /usr/src -f opentelemetry-proto.tar.gz \
    && tar -zxC /usr/src -f opentelemetry-cpp.tar.gz \
    && tar -zxC /usr/src -f opentelemetry-cpp-contrib-webserver.tar.gz \
    && tar -zxC /usr/src -f nginx-lua-prometheus.tar.gz nginx-lua-prometheus-$NGINX_LUA_PROMETHEUS_TAG/prometheus.lua nginx-lua-prometheus-$NGINX_LUA_PROMETHEUS_TAG/prometheus_keys.lua nginx-lua-prometheus-$NGINX_LUA_PROMETHEUS_TAG/prometheus_resty_counter.lua \
	&& tar -zxC /usr/src -f ngx_brotli.tar.gz \
    && echo "[BUILD_PHASE] start install overridden luajit" \
    && cd /usr/src/luajit2-${LUAJIT_VERSION} \
    && make -j$(getconf _NPROCESSORS_ONLN) BUILDMODE=static \
    && make install \
    && cd / \
    && echo "[BUILD_PHASE] end install overridden luajit" \
	&& echo "[BUILD_PHASE] start install openresty module" \
	&& tar -zxC /usr/src -f openresty-$OPENRESTY_VERSION.tar.gz \
    && cp -R /usr/src/openresty-$OPENRESTY_VERSION/bundle/headers-more-nginx-module-$NGINX_HEADERS_MORE_NGINX_MODULE_VERSION /usr/src/headers-more-nginx-module-$NGINX_HEADERS_MORE_NGINX_MODULE_VERSION/ \
	&& cd /usr/src/openresty-$OPENRESTY_VERSION/bundle/lua-resty-core-$NGINX_LUA_RESTY_CORE_VERSION \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	&& cd /usr/src/openresty-$OPENRESTY_VERSION/bundle/lua-resty-lrucache-$NGINX_LUA_RESTY_LRUCASHE_VERSION \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	&& cd /usr/src/openresty-$OPENRESTY_VERSION/bundle/lua-cjson-$NGINX_LUA_RESTY_CJSON_VERSION \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
    && cd /usr/src/openresty-$OPENRESTY_VERSION/bundle/lua-resty-websocket-$LUA_RESTY_WEBSOCKET_VERSION \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
	&& echo "[BUILD_PHASE] end install openresty module" \
    && echo "[BUILD_PHASE] install opentelemetry-cpp "\
    && cd /usr/src/opentelemetry-cpp-$OTEL_CPP_VERSION \
    && mkdir /usr/lib/opentelemetry-cpp \
    && cd /usr/lib/opentelemetry-cpp \
    && cmake /usr/src/opentelemetry-cpp-$OTEL_CPP_VERSION \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
        -DBUILD_TESTING=OFF \
        -DWITH_EXAMPLES=OFF \
        -DWITH_OTLP_GRPC=ON \
        -DWITH_OTLP_HTTP=OFF \
        -DWITH_ABSEIL=ON \
        -DOTELCPP_PROTO_PATH=/usr/src/opentelemetry-proto-$OTEL_PROTO_VERSION \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && echo "[BUILD_PHASE] end install opentelemetry-cpp" \
    && echo "[BUILD_PHASE] install nginx-lua-prometheus" \
    && mkdir $LUA_LIB_ROOT/nginx-lua-prometheus \
    && cp /usr/src/nginx-lua-prometheus-$NGINX_LUA_PROMETHEUS_TAG/*.lua $LUA_LIB_ROOT/nginx-lua-prometheus \
    && echo "[BUILD_PHASE] end install nginx-lua-prometheus" \
    && echo "[BUILD_PHASE] install nginx" \
	&& cd /usr/src/nginx-$NGINX_VERSION \
	&& ./configure $CONFIG --with-debug \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& mv objs/nginx objs/nginx-debug \
	&& ./configure $CONFIG \
	&& make -j$(getconf _NPROCESSORS_ONLN) \
	&& make install \
	&& rm -rf /etc/nginx/html/ \
	&& mkdir /etc/nginx/conf.d/ \
	&& mkdir -p /usr/share/nginx/html/ \
	&& install -m644 html/index.html /usr/share/nginx/html/ \
	&& sed -i 's/nginx//g' /usr/share/nginx/html/index.html \
	&& install -m644 html/50x.html /usr/share/nginx/html/ \
	&& sed -i 's/nginx//g' /usr/share/nginx/html/50x.html \
	&& install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
	&& ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
	&& strip /usr/sbin/nginx* \
    && echo "[BUILD_PHASE] end install nginx" \
    && echo "[BUILD_PHASE] install opentelemetry-cpp-contrib" \
    ## hack for avoiding cmake targets conflict, need to be removed when OTEL_WEBSERVER will be updated to > 1.1.0
    && sed -i '/find_package(Protobuf REQUIRED)/d' \
        /usr/src/opentelemetry-cpp-contrib-webserver-v${OTEL_WEBSERVER_VERSION}/instrumentation/nginx/CMakeLists.txt \
    && cd /usr/src/opentelemetry-cpp-contrib-webserver-v$OTEL_WEBSERVER_VERSION/instrumentation/nginx \
    && mkdir /usr/lib/opentelemetry-cpp-contrib \
    && cd /usr/lib/opentelemetry-cpp-contrib \
    && cmake /usr/src/opentelemetry-cpp-contrib-webserver-v$OTEL_WEBSERVER_VERSION/instrumentation/nginx \
        -DOPENTELEMETRY_CPP_INCLUDE_DIRS=/usr/lib/opentelemetry-cpp/include \
        -DCMAKE_PREFIX_PATH=/usr/local \
        -DNGINX_BIN=/usr/sbin/nginx \
        -DCURL_LIBRARY=/usr/lib/libcurl.so.4.8.0 \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && echo "[BUILD_PHASE] end install opentelemetry-cpp-contrib"

RUN scanelf --needed --nobanner /usr/sbin/nginx /usr/bin/envsubst \
    | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
    | sort -u \
    | xargs -r apk info --installed \
    | sort -u \
    > /tmp/rundeps.txt

# ---- Runtime stage ----
FROM ${BASE_IMAGE}
LABEL maintainer="qubership"

ARG BASE_IMAGE_TAG=qubership-nginx-base:unknown
ARG UID=10001
ARG GID=root

ENV NGINX_VERSION=1.28.2
ENV LUA_LIB_ROOT=/usr/local/lib/lua
ENV LUA_SHARE_ROOT=/usr/local/share/lua/5.4
ENV LUA_PATH=$LUA_LIB_ROOT/?.lua;$LUA_SHARE_ROOT/?.lua;

# switch to root for build phase
USER root
RUN echo $BASE_IMAGE_TAG > /etc/base-image-release

COPY images/nginx/base-image-conf/probes-locations.conf /usr/src/

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /usr/sbin/nginx-debug /usr/sbin/nginx-debug
COPY --from=builder /etc/nginx/ /etc/nginx/
COPY --from=builder /usr/lib/nginx/modules/ /usr/lib/nginx/modules/
COPY --from=builder /usr/local/ /usr/local/
COPY --from=builder /usr/share/nginx/html/ /usr/share/nginx/html/
COPY --from=builder /usr/bin/envsubst /usr/bin/envsubst
COPY --from=builder \
    /usr/lib/libabsl_*.so* \
    /usr/lib/libupb_*.so* \
    /usr/lib/libgrpc*.so* \
    /usr/lib/libgpr.so* \
    /usr/lib/libprotobuf.so* \
    /usr/lib/libstdc++.so* \
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
    /usr/lib/
COPY --from=builder \
    /usr/lib/opentelemetry-cpp-contrib/otel_ngx_module.so \
    /usr/lib/opentelemetry-cpp-contrib/


RUN rm -rf /etc/nginx/modules \
    && ln -s /usr/lib/nginx/modules /etc/nginx/modules \
    && mkdir -p /var/log/nginx \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && mkdir /etc/nginx/base-image-conf \
    && cp /usr/src/probes-locations.conf /etc/nginx/base-image-conf/ \
    && touch /run/nginx.pid \
    && chown ${UID}:${GUID} /run /run/nginx.pid

VOLUME /var/log
VOLUME /tmp

USER ${UID}
