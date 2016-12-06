# swtpm builder
This is a simple project to build the great software tpm emulator https://github.com/stefanberger/swtpm.git in a container. This eliminates all of the complexities of setting up the build environment and just leaves you with compiled libraries and binaries.

## Installation
Prerequisites:

* docker
* git

Clone this repository:

````
git clone https://github.com/deitch/swtpm-build.git
````

## Building
Simple:

````
make build
````

This will:

1. Create an image with everything built into it: `swtpmbuild:latest`
2. Create a subdirectory in the current directory `./dist/`
3. Copy all of the libraries and binaries for libtpms and swtpm into `./dist/` in the right structure

From there, you can install them as is to your preferred path: `/usr`, `/usr/local`, whatever suits you.

## Cleaning

````
make clean
````


