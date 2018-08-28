FROM alpine:3.4 as buider

ENV NGINX_VERSION=1.15.2

RUN apk --no-cache --update add \
        ca-certificates \
        libuuid \
        apr \
        apr-util \
        libjpeg-turbo \
        icu \
        icu-libs \
        openssl \
        pcre \
        zlib

RUN	apk --no-cache --update add -t .build-deps \
        apache2-dev \
        apr-dev \
        apr-util-dev \
        build-base \
        curl \
        icu-dev \
        libjpeg-turbo-dev \
        linux-headers \
        gperf \
        openssl-dev \
        pcre-dev \
        python \
		git \
        zlib-dev

WORKDIR /tmp


RUN	git clone --recursive https://github.com/google/ngx_brotli.git && \
	wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
	tar -xvzf nginx-${NGINX_VERSION}.tar.gz && \
	mv nginx-${NGINX_VERSION}/ nginx && \
	cd nginx && \
	./configure --with-compat --add-dynamic-module=/tmp/ngx_brotli && \
	make modules

FROM pagespeed/nginx-pagespeed:ngx1.15

COPY --from=buider /tmp/nginx/objs/ngx_http_brotli_static_module.so /etc/nginx/modules
COPY --from=buider /tmp/nginx/objs/ngx_http_brotli_filter_module.so /etc/nginx/modules
