// package name: ngx_http_grpc_backend_module
package main

import (
	"C"
	"context"
	"log"
	"time"

	"google.golang.org/grpc"
	pb "google.golang.org/grpc/examples/helloworld/helloworld"
)

const (
	address = "localhost:50051"
)

// main is required for the file to compile to an object.
func main() {}

func init() {
}

//export HelloWorld
func HelloWorld(svc *C.char) *C.char {
	name := (C.GoString(svc))

	log.Printf("[debug] HelloWorld: name=%s", name)

	conn, err := grpc.Dial(address, grpc.WithInsecure())
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()
	c := pb.NewGreeterClient(conn)

	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	r, err := c.SayHello(ctx, &pb.HelloRequest{Name: name})
	if err != nil {
		log.Fatalf("could not greet: %v", err)
	}
	log.Printf("Greeting: %s", r.Message)

	return C.CString(r.Message)
}
