include .env

DOCKER_DIR := docker-build

all: build
build: apache httperf tsung

apache:
	docker build -t ${IMAGE_PREFIX}/apache:latest -f ${DOCKER_DIR}/apache.Dockerfile .

httperf:
	docker build -t ${IMAGE_PREFIX}/httperf:latest -f ${DOCKER_DIR}/httperf.Dockerfile .

tsung:
	docker build -t ${IMAGE_PREFIX}/tsung:build -f ${DOCKER_DIR}/tsung.Dockerfile --target build .
	docker build -t ${IMAGE_PREFIX}/tsung:latest -f ${DOCKER_DIR}/tsung.Dockerfile .

clean:
	docker image prune -f
	docker builder prune -f
	docker buildx prune -f

net:
	docker network create wbx_net || true

del-net:
	docker network rm wbx_net || true
