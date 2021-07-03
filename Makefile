.PHONY: all image clean deploy

all: image

DOCKER_NAME=zephyr-min
DOCKER_TAG=latest
REGISTRY=192.168.1.2

image:
	docker build \
		--file Dockerfile \
		--tag $(DOCKER_NAME):dev .

enter: image
	docker run \
		--rm \
		--interactive \
		--tty=true \
		$(DOCKER_NAME):dev /bin/bash

deploy:
	docker tag $(DOCKER_NAME):dev $(REGISTRY):5000/$(DOCKER_NAME):$(DOCKER_TAG)
	docker push $(REGISTRY):5000/$(DOCKER_NAME):$(DOCKER_TAG)

