build:
	docker build -t swtpmbuild .
	docker run --rm -v ${PWD}/dist:/mnt swtpmbuild /tpm /mnt

clean:
	rm -rf ${PWD}/dist

