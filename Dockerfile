# wisca/wiscanet-docker:18.04

# Provides a base Ubuntu (18.04) image with latest UHD and WiscaNET installed

FROM        ubuntu:18.04
MAINTAINER  Ettus Research

# Last build date - this can be updated whenever there are security updates so
# that everything is rebuilt
ENV         security_updates_as_of 2019-05-15

# This will make apt-get install without question
ARG         DEBIAN_FRONTEND=noninteractive
ARG         UHD_TAG=v3.14.0.0
ARG         WISCANET_TAG=HEAD
ARG         MAKEWIDTH=25

# Install security updates and required packages
RUN         apt-get update
RUN         apt-get -y install -q \
                build-essential \
                ccache \
                git \
                python3-dev \
                python3-pip \
                curl
# Install UHD dependencies
RUN         apt-get -y install -q \
                libboost-all-dev \
                libusb-1.0-0-dev \
                libudev-dev \
                python3-mako \
                doxygen \
                python3-docutils \
                cmake \
                python3-requests \
                python3-numpy \
                dpdk \
                libdpdk-dev \
                libssl-dev \
                libcrypto++-dev

RUN          rm -rf /var/lib/apt/lists/*

RUN          mkdir -p /usr/local/src
RUN          git clone https://github.com/EttusResearch/uhd.git /usr/local/src/uhd
RUN          cd /usr/local/src/uhd/ && git checkout $UHD_TAG
RUN          mkdir -p /usr/local/src/uhd/host/build
WORKDIR      /usr/local/src/uhd/host/build
RUN          cmake .. -DENABLE_PYTHON3=ON -DUHD_RELEASE_MODE=release -DCMAKE_INSTALL_PREFIX=/usr
RUN          make -j $MAKEWIDTH
RUN          make install
RUN          uhd_images_downloader
WORKDIR      /
RUN          git clone https://gitbliss.asu.edu/jholtom/wiscanet_source /usr/local/src/wiscanet_source
RUN          cd /usr/local/src/wiscanet_source && git checkout $WISCANET_TAG
RUN          mkdir -p /usr/local/src/wiscanet_source/src/build
WORKDIR      /usr/local/src/wiscanet_source/src
RUN          make -j $MAKEWIDTH
