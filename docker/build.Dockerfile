FROM golang:1.9

RUN \
  apt-get -yqq update && \
  apt-get -yqq install  \
  build-essential \
  curl \
  dnsutils \
  libpcre3 \
  libpcre3-dev \
  libssl-dev \
  unzip \
  vim \
  zlib1g-dev

RUN \
  cd /tmp && \
  curl -sLo nginx.tgz https://nginx.org/download/nginx-1.12.2.tar.gz && \
  tar -xzvf nginx.tgz


RUN \
  cd /tmp && \
  curl -sLo ndk.tgz https://github.com/simpl/ngx_devel_kit/archive/v0.3.0.tar.gz && \
  tar -xzvf ndk.tgz

RUN \
  go get -u google.golang.org/grpc && \
  go get -u github.com/golang/protobuf/protoc-gen-go && \
  export PATH=$PATH:$GOPATH/bin

ADD . /tmp/ngx_http_grpc_backend_module

RUN \
  mkdir -p /usr/local/nginx/ext && \
  mkdir -p /go/src/github.com/myeh/ngx_http_grpc_backend_module && \
  cp -R /tmp/ngx_http_grpc_backend_module /go/src/github.com/myeh/ && \
  cd /go/src/github.com/myeh/ngx_http_grpc_backend_module && \
  CGO_CFLAGS="-I /tmp/ngx_devel_kit-0.3.0/src" \
  go build \
    -buildmode=c-shared \
    -o /usr/local/nginx/ext/ngx_http_grpc_backend_module.so \
    src/ngx_http_grpc_backend_module.go

RUN \
  cd /tmp/nginx-* && \
  CFLAGS="-g -O0" \
  ./configure \
    --with-debug \
    --add-module=/tmp/ngx_devel_kit-0.3.0 \
    --add-module=/go/src/github.com/myeh/ngx_http_grpc_backend_module \
    && \
  make && \
  make install

COPY docker/nginx.conf /usr/local/nginx/conf/nginx.conf

COPY docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["/usr/local/bin/docker-entrypoint.sh"]
