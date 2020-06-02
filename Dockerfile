# jholtom/wiscanet-docker:latest

# Provides a base Fedora 32 image with latest UHD and WiscaNET installed
FROM        registry.fedoraproject.org/fedora:latest
MAINTAINER  ASU Center for Wireless Information Systems and Computational Architectures (WISCA)

# Some system arguments
ARG         UHD_TAG=v3.15.0.0
ARG         WISCANET_TAG=HEAD
ARG         MAKEWIDTH=3

EXPOSE 22
EXPOSE 9000
EXPOSE 9940
EXPOSE 9942
EXPOSE 9943

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
                curl \
                openssh-server \
                passwd

# Install UHD dependencies
RUN         dnf -y install -q\
                boost-devel \
                libusbx-devel \
                python3-mako \
                doxygen \
                python3-docutils \
                python3-requests \
                python3-numpy \
                dpdk \
                dpdk-devel \
                openssl-devel \
                fftw-devel \
                cppunit-devel \
                boost-devel \
                numpy \
                gsl-devel \
                python-devel \
                pygsl \
                python-cheetah \
                python-mako \
                python-lxml \
                libusbx-devel \
                cmake \
                python-docutils \
                gtk2-engines \
                xmlrpc-c-"*" \
                orc-devel \
                python-sphinx \
                zeromq \
                zeromq-devel \
                python-requests \
                doxygen \
                zeromq-ada-devel \
                cppzmq-devel \
                python-zmq \
                czmq \
                uwsgi-logger-zeromq \
                pygtk2 \
                ncurses-"*" \
                thrift-devel \
                libpng12-devel \
                freetype-devel \
                blas-devel \
                lapack-devel \
                libXt

# Install WISCANet dependencies
RUN         dnf -y install -q\
                tinyxml-devel \
                procps \
                which
        #                octave \
        #        octave-devel \
        #       octave-signal \
        #        octave-communications \
        #        octave-miscellaneous \
        #        octave-general \
RUN         dnf clean all && rm -rf /var/cache/yum

# Build UHD Driver
RUN          mkdir -p /usr/local/src
RUN          git clone https://github.com/EttusResearch/uhd.git /usr/local/src/uhd
RUN          cd /usr/local/src/uhd/ && git checkout $UHD_TAG
RUN          mkdir -p /usr/local/src/uhd/host/build
WORKDIR      /usr/local/src/uhd/host/build
RUN          cmake .. -DENABLE_PYTHON3=ON -DUHD_RELEASE_MODE=release -DCMAKE_INSTALL_PREFIX=/usr
RUN          make -j $MAKEWIDTH
RUN          make install
RUN          uhd_images_downloader

# Add MATLAB to the system
ADD matlab-install/MATLAB /usr/local/
ENV PATH="/usr/local/MATLAB/bin:${PATH}"
# Enable MEX
RUN /usr/local/MATLAB/bin/mex -v -setup && /usr/local/MATLAB/bin/mex -v -setup C++

# Begin building WISCANET
RUN          echo "Test flag to trigger docker rebuild of WISCA Tooling 1"
WORKDIR      /
RUN          git clone https://gitbliss.asu.edu/jholtom/wiscanet_source /usr/local/src/wiscanet_source
RUN          cd /usr/local/src/wiscanet_source && git checkout $WISCANET_TAG
# If not operating with access to gitbliss, comment prior two lines and uncomment the ADD statement
#ADD wiscanet_source /usr/local/src/wiscanet_source
RUN          mkdir -p /usr/local/src/wiscanet_source/src/build
WORKDIR      /usr/local/src/wiscanet_source/src
RUN          make -j $MAKEWIDTH

COPY octave-matlab /usr/bin/matlab
RUN chmod +x /usr/bin/matlab

# Add WISCA User and give nopasswd sudo
RUN useradd -ms /bin/bash wisca -G wheel && echo "wisca:wisca" | chpasswd
RUN echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER wisca
ENV HOME /home/wisca
WORKDIR /home/wisca
RUN git clone https://gitbliss.asu.edu/jholtom/wiscanet-deploy wdemo
RUN cd wdemo && git checkout $WISCANET_TAG
# Again, if not operating with access to gitbliss, comment prior two lines and uncomment following ADD statement
# ADD wiscanet-deploy /home/wisca/wdemo
WORKDIR /home/wisca/wdemo/

RUN cp /usr/local/src/wiscanet_source/src/build/cnode/bin/cnode /home/wisca/wdemo/run/cnode/bin/
RUN cp /usr/local/src/wiscanet_source/src/build/enode/bin/enode /home/wisca/wdemo/run/enode/bin/
RUN cp /usr/local/src/wiscanet_source/src/build/enode/bin/uControl /home/wisca/wdemo/run/enode/bin/
RUN cp -rf /usr/local/src/wiscanet_source/src/build/enode/mat /home/wisca/wdemo/run/enode/
RUN cp -rf /usr/local/src/wiscanet_source/umat/mat /home/wisca/wdemo/run/usr/
RUN chmod +x run/cnode/bin/cnode && chmod +x run/enode/bin/enode && chmod +x run/enode/bin/uControl

USER root
ENV HOME /root
RUN systemctl enable sshd
RUN systemctl enable systemd-timesyncd


CMD [ "/sbin/init" ]
