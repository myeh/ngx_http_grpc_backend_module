IMAGE_TAG ?= myeh/nginx-grpc

docker:
	@docker build -t "${IMAGE_TAG}" -f docker/build.Dockerfile .
	@docker run -it -p 8080:80 --rm --name nginx "${IMAGE_TAG}"
.PHONY: docker

deps:
	@cd src/ && dep ensure -update
.PHONY: deps
