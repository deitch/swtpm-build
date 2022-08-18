# builder for swtpm, includes both musl ones for alpine and glibc for other OSes
ARG LIBTPMS_COMMIT=0c2bc32a21e2c7218faa8cd6d5cf31b13835e6d5
ARG SWTPM_COMMIT=0ebe80466fcbe7605db5d413f4370f2ccddf672b
ARG TARGET_DIR=/tpm

FROM alpine:3.16 as git
ARG LIBTPMS_COMMIT
ARG SWTPM_COMMIT
ARG TARGET_DIR

# git for cloning the repos
RUN apk add git

ENV src /var/tmp/src
RUN mkdir -p ${src}

RUN git clone https://github.com/stefanberger/libtpms.git ${src}/libtpms
RUN cd ${src}/libtpms && git checkout ${LIBTPMS_COMMIT}
RUN git clone https://github.com/stefanberger/swtpm.git ${src}/swtpm
RUN cd ${src}/swtpm && git checkout ${SWTPM_COMMIT}


# alpine for musl
FROM alpine:3.16 as alpine
ARG TARGET_DIR

ENV src /var/tmp/src
COPY --from=git ${src} ${src}

# just update
RUN apk update

# dependencies for libtpms
RUN apk add openssl-dev automake autoconf build-base libtool make bash

RUN mkdir -p ${TARGET_DIR}

# install libtpms thanks to stefanberger
WORKDIR ${src}/libtpms
RUN ./autogen.sh --prefix=/usr --libdir=/usr/lib --with-tpm2 --with-openssl
RUN make -j4
RUN ["/bin/bash", "-c", "make -j4 check"]
RUN make install
# we need to install again to default dir or swtpm will not install
# see https://github.com/stefanberger/swtpm/issues/18
RUN make prefix=/usr/local install
RUN make prefix=${TARGET_DIR} install

# dependencies for swtpm - there are duplicates from libtpms, but it just checks local cache anyways
RUN apk add socat gawk libtasn1-dev gnutls gnutls-utils gnutls-dev expect python3 libseccomp-dev json-glib-dev \
  autoconf \
  automake \
  gettext \
  libtool \
  gcc \
  musl-dev \
  openssl \
  openssl-dev \
  bash

WORKDIR ${src}/swtpm
RUN ./autogen.sh --prefix=/usr --libdir=/usr/lib --with-openssl --with-tss-user=root --with-tss-group=root
RUN make -j4
RUN ["/bin/bash", "-c", "make -j4 check"]
RUN make install
RUN make exec_prefix=${TARGET_DIR} install

# ubuntu build                                                                                                                                                                               [4/1835]
FROM ubuntu:20.04 as ubuntu
ARG TARGET_DIR

ENV src /var/tmp/src
COPY --from=git ${src} ${src}

RUN apt update -y
RUN apt install -y locales
RUN locale-gen en_US.UTF-8
    #dpkg-reconfigure locales
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y install automake autoconf libtool gcc build-essential libssl-dev dh-exec pkg-config dh-autoreconf


WORKDIR ${src}/libtpms
RUN ./autogen.sh --with-openssl
RUN make dist
RUN make -j4
RUN make -j4 check
RUN make install
# we need to install again to default dir or swtpm will not install
# see https://github.com/stefanberger/swtpm/issues/18
RUN make prefix=/usr/local install
RUN make prefix=${TARGET_DIR} install

WORKDIR ${src}/swtpm
RUN apt-get install dh-autoreconf libssl-dev \
     libtasn1-6-dev pkg-config \
     net-tools iproute2 libjson-glib-dev \
     libgnutls28-dev expect gawk socat \
     libseccomp-dev make -y
RUN ./autogen.sh --with-openssl --prefix=/usr
RUN make -j4
RUN make -j4 check
RUN make install
RUN make exec_prefix=${TARGET_DIR} install

# our installer
FROM scratch
ARG TARGET_DIR
COPY --from=alpine ${TARGET_DIR} ${TARGET_DIR}/musl
COPY --from=ubuntu ${TARGET_DIR} ${TARGET_DIR}/glibc
