.PHONY: build clean

BUILD_CONTAINER_NAME?=swtpmbuild

build:
	docker build -t swtpmbuild .
	docker container create --name=$(BUILD_CONTAINER_NAME) swtpmbuild sh
	docker cp $(BUILD_CONTAINER_NAME):/tpm ${PWD}/dist
	docker container rm $(BUILD_CONTAINER_NAME)

clean:
	rm -rf ${PWD}/dist
	docker rm $(BUILD_CONTAINER_NAME)
