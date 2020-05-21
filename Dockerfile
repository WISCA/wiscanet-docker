# jholtom/wiscanet-docker:latest

# Provides a base Fedora Latest image with latest UHD and WiscaNET installed
FROM        fedora:latest
MAINTAINER  ASU Center for Wireless Information Systems and Computational Architectures (WISCA)

# Some system arguments
ARG         UHD_TAG=v3.14.0.0
ARG         WISCANET_TAG=HEAD
ARG         MAKEWIDTH=25

# Install security updates and required packages
RUN         dnf -y update
RUN         dnf -y install \
                make \
                automake \
                gcc \
                gcc-c++ \
                ccache \
                git \
                python3-devel \
                python3-pip \
                curl
# Install UHD dependencies
RUN         dnf -y install \
                boost-devel \
                libusb-devel \
                python3-mako \
                doxygen \
                python3-docutils \
                cmake \
                python3-requests \
                python3-numpy \
                dpdk \
                dpdk-devel \
                openssl-devel \
                tinyxml-devel \
                octave \
                octave-signal \
                octave-communications \
                octave-miscellaneous \
                octave-general

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
