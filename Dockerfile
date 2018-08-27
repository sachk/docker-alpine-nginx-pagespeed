FROM alpine:3.4

# Inspired by wunderkraut/alpine-nginx-pagespeed (aka ilari/alpine-nginx-pagespeed:latest) with some extra modules.

ENV NGINX_VERSION=1.15.2

ENV PAGESPEED_VERSION=1.13.35.2-stable

ENV PS_NGX_EXTRA_FLAGS="--with-ipv6 \
        --prefix=/var/lib/nginx \
        --sbin-path=/usr/sbin \
        --modules-path=/usr/lib/nginx \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-file-aio \
        --with-http_v2_module \
        --without-http_autoindex_module \
        --without-http_browser_module \
        --without-http_geo_module \
        --without-http_map_module \
        --without-http_memcached_module \
        --without-http_userid_module \
        --without-mail_pop3_module \
        --without-mail_imap_module \
        --without-mail_smtp_module \
        --without-http_split_clients_module \
        --without-http_scgi_module \
        --without-http_referer_module \
        --without-http_upstream_ip_hash_module \
        --prefix=/etc/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --http-log-path=/var/log/nginx/access.log \
        --error-log-path=/var/log/nginx/error.log \
        --pid-path=/var/run/nginx.pid"

RUN apk --no-cache add \
        ca-certificates \
        libuuid \
        apr \
        apr-util \
        libjpeg-turbo \
        icu \
        icu-libs \
        openssl \
        pcre \
        zlib \
        git

RUN apk --no-cache add -t .build-deps \
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
        zlib-dev

WORKDIR /tmp


#RUN     bash build_ngx_pagespeed.sh -v ${PAGESPEED_VERSION} -n ${NGINX_VERSION} -p -y -a "\
#       --with-http_ssl_module \
#       --with-http_gzip_static_module \
#       --with-file-aio \
#       --with-http_v2_module \
#       --without-http_autoindex_module \
#       --without-http_browser_module \
#       --without-http_geo_module \
#       --without-http_map_module \
#       --without-http_memcached_module \
#       --without-http_userid_module \
#       --without-mail_pop3_module \
#       --without-mail_imap_module \
#       --without-mail_smtp_module \
#       --without-http_split_clients_module \
#       --without-http_scgi_module \
#       --without-http_referer_module \
#       --without-http_upstream_ip_hash_module \
#       --pid-path=/var/run/nginx.pid "

# Brotoli

RUN     git clone --recursive https://github.com/google/ngx_brotli.git && \
        wget https://github.com/apache/incubator-pagespeed-ngx/archive/v${PAGESPEED_VERSION}.zip && \
        unzip v${PAGESPEED_VERSION}.zip && \
        nps_dir=$(find . -name "*pagespeed-ngx-${PAGESPEED_VERSION}" -type d) && \
        cd "$nps_dir" && \
        NPS_RELEASE_NUMBER=${PAGESPEED_VERSION/stable/} && \
        psol_url=https://dl.google.com/dl/page-speed/psol/${NPS_RELEASE_NUMBER}.tar.gz && \
        [ -e scripts/format_binary_url.sh ] && psol_url=$(scripts/format_binary_url.sh PSOL_BINARY_URL) && \
        wget ${psol_url} && \
        tar -xzvf $(basename ${psol_url})  # extracts to psol/ && \
        wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
        tar -xvzf nginx-${NGINX_VERSION}.tar.gz && \
        cd nginx-${NGINX_VERSION}/ && \
        ./configure --add-module=$HOME/$nps_dir --add-module $HOME/ngx_brotli ${PS_NGX_EXTRA_FLAGS} && \
        make && \
        make install

# Clean-up:
RUN cd && \
    apk del .build-deps && \
    rm -rf /tmp/* && \
    # forward request and error logs to docker log collector
    mkdir -p /var/log/nginx && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    # Make PageSpeed cache writable:
    mkdir -p /var/cache/ngx_pagespeed && \
    chmod -R o+wr /var/cache/ngx_pagespeed

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
