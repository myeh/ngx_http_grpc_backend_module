# nginx + grpc

This repository contains an [nginx](https://nginx.org) module extension for
invoking a call to a GRPC server.

This is code is based off of
https://github.com/hashicorp/ngx_http_grpc_backend_module.git

**This code is for example purposes only. It demonstrates both the ability to
call Go code from C and the ability to make grpc calls. It is
not production ready and should be considered _inspiration only_.**


## Usage

This module installs a `helloworld` directive inside the `location` block, and sets
the resulting `$result` variable.

```nginx
http {
  server {
    listen       80;
    server_name  example.com;

    location /hello {
      helloworld $result world;
    }
  }
}
```


## Architecture


This requires Golang to compile the dynamic library `.so` file. In
theory, this could be compiled in advance by a CI/CD system. There is no need
for the Golang _runtime_, since the runtime is compiled into the dynamic library.


The general flow is as follows:

1. A request comes into nginx that matches a defined `location` block with a
`helloworld` directive.

1. nginx calls the `ngx_http_grpc_backend` function with two arguments.

  1. The first argument is the variable in which to store the result
  (e.g. `$result`).

  1. The second argument is the name of the variable to pass into the grpc Greeter.

1. The `ngx_http_grpc_backend` calls `dlopen` on the shared C library (the
`.so` file mentioned above), and executes the Go function by calling its symbol.

1. The Go function makes a call with the Greeter grpc server

## Installation

This installation guide uses ubuntu/debian. Adapt as-needed for other platforms.

### Prerequisites

- [Golang](https://golang.org) >= 1.9
- Standard build tools, including GCC

### Steps

1. Install the necessary build tools:

    ```sh
    $ apt-get -yqq install build-essential curl git libpcre3 libpcre3-dev libssl-dev zlib1g-dev
    ```

1. Download and extract nginx source:

    ```sh
    $ cd /tmp
    $ curl -sLo nginx.tgz https://nginx.org/download/nginx-1.12.2.tar.gz
    $ tar -xzvf nginx.tgz
    ```

1. Download and extract the nginx development kit (ndk):

    ```sh
    $ cd /tmp
    $ curl -sLo ngx_devel_kit-0.3.0.tgz https://github.com/simpl/ngx_devel_kit/archive/v0.3.0.tar.gz
    $ tar -xzvf ngx_devel_kit-0.3.0.tgz
    ```

1. Download/clone this repository:

    ```sh
    $ git clone https://github.com/myeh/ngx_http_grpc_backend_module /go/src/github.com/myeh/ngx_http_grpc_backend_module
    ```

1. Compile the Go code as a shared C library which nginx will dynamically load.
This uses CGO and binds to the nginx development kit:

    ```sh
    $ cd /tmp/ngx_http_grpc_backend_module/src
    $ mkdir -p /usr/local/nginx/ext
    $ CGO_CFLAGS="-I /tmp/ngx_devel_kit-0.3.0/src" \
        go build \
          -buildmode=c-shared \
          -o /usr/local/nginx/ext/ngx_http_grpc_backend_module.so \
          src/ngx_http_grpc_backend_module.go
    ```

    This will compile the object file with symbols to
    `/usr/local/nginx/ext/nginx_http_grpc_backend_module.so`. Note that the
    name and location of this file is important - it will be `dlopen`ed at
    runtime by nginx.

1. Compile and install nginx with the modules:

    ```sh
    $ cd /tmp/nginx-1.12.2
    $ CFLAGS="-g -O0" \
        ./configure \
          --with-debug \
          --add-module=/tmp/ngx_devel_kit-0.3.0 \
          --add-module=/go/src/github.com/myeh/ngx_http_grpc_backend_module
    $ make
    $ make install
    ```

1. Add the required nginx configuration and restart nginx:

    ```nginx
    http {
      server {
        listen       80;
        server_name  example.com;

        location /hello {
          helloworld $result world;
        }
      }
    }
    ```


## Development

There is a sample Dockerfile and entrypoint which builds and runs this custom
nginx installation with all required modules.

