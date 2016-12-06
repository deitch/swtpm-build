FROM ubuntu:16.04
MAINTAINER Avi Deitcher <https://github.com/deitch>
LABEL Description="swtpm Build" Version="1.0"


# Setup the environment
ENV DEBIAN_FRONTEND=noninteractive


# Install packages
RUN apt-get -q update && \
    apt-get -y -qq upgrade && \
    apt-get install -y -qq \
	automake \
	expect \
	gnutls-bin \
	libgnutls-dev \
	git \
	gawk \
	m4 \
	socat \
	fuse \
	libfuse-dev \
	tpm-tools \
	libgmp-dev \
	libtool \
	libglib2.0-dev \
	libnspr4-dev \
	libnss3-dev \
	libssl-dev \
	libtasn1-dev \
	&& apt-get clean


# Configure locales
RUN locale-gen en_US.UTF-8 && \
    dpkg-reconfigure locales


ENV src /var/tmp/src
ENV target /tpm
RUN mkdir -p ${src}
RUN mkdir -p ${target}

# install libtpms thanks to stefanberger
RUN git clone https://github.com/stefanberger/libtpms.git ${src}/libtpms
WORKDIR ${src}/libtpms
RUN ./bootstrap.sh
RUN ./configure --prefix=${target} --with-openssl
RUN make
RUN make install
# we need to install again to default dir or swtpm will not install
# see https://github.com/stefanberger/swtpm/issues/18
RUN make prefix=/usr/local install

# install swtpm thanks to stefanberger
RUN git clone https://github.com/stefanberger/swtpm.git ${src}/swtpm
WORKDIR ${src}/swtpm
RUN ./bootstrap.sh
RUN ./configure --prefix=${target} --with-openssl
RUN make
RUN make install

# our installer
COPY dupdir /usr/local/bin

# at this point, everything is build and ready
WORKDIR ${src}

ENTRYPOINT ["dupdir"]

