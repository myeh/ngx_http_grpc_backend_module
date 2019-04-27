#!/usr/bin/env bash
set -e

echo "Starting greeter server"
go run /go/src/google.golang.org/grpc/examples/helloworld/greeter_server/main.go &


echo "Starting nginx"
export LD_LIBRARY_PATH="/usr/local/nginx/ext:$LD_LIBRARY_PATH"
/usr/local/nginx/sbin/nginx
sleep infinity
