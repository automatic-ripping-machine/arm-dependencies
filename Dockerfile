###########################################################
# base image, used for build stages and final images
FROM phusion/baseimage:focal-1.2.0 as base
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir /opt/arm
WORKDIR /opt/arm

COPY ./scripts/add-ppa.sh /root/add-ppa.sh

# start by updating and upgrading the OS
RUN \
    apt update && \
    apt upgrade -y -o Dpkg::Options::="--force-confold"

# setup gnupg/wget for add-ppa.sh
RUN install_clean \
        wget \
        build-essential \
        libcurl4-openssl-dev \
        libssl-dev \
        gnupg \
        libudev-dev \
        udev \
        python3 \
        python3-dev \
        python3-pip \
        nano \
        vim

# add the PPAs we need, using add-ppa.sh since add-apt-repository is unavailable
RUN \
    bash /root/add-ppa.sh ppa:mc3man/focal6 && \
    bash /root/add-ppa.sh ppa:heyarje/makemkv-beta && \
    bash /root/add-ppa.sh ppa:stebbins/handbrake-releases


###########################################################
# install deps specific to the docker deployment
FROM base as deps-docker
RUN install_clean gosu


###########################################################
# install deps for ripper
FROM deps-docker as deps-ripper
RUN install_clean \
        abcde \
        eyed3 \
        atomicparsley \
        cdparanoia \
        eject \
        ffmpeg \
        flac \
        glyrc \
        default-jre-headless \
        libavcodec-extra

# install python reqs
COPY requirements.txt /requirements.txt
RUN \
    pip3 install --upgrade pip wheel setuptools psutil pyudev && \
    pip3 install --ignore-installed --prefer-binary -r /requirements.txt

# install libdvd-pkg
RUN \
    install_clean libdvd-pkg && \
    dpkg-reconfigure libdvd-pkg


###########################################################
# Final image pushed for use
FROM deps-ripper as arm-dependencies

# install makemkv and handbrake
RUN install_clean \
        rsyslog \
        handbrake-cli \
        makemkv-bin \
        makemkv-oss

# clean up apt
RUN apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN sed -i '/imklog/s/^/#/' /etc/rsyslog.conf

# reset to default after build
ENV DEBIAN_FRONTEND=newt

# set metadata
LABEL org.opencontainers.image.source=https://github.com/shitwolfymakes/arm-dependencies
LABEL org.opencontainers.image.license=MIT
LABEL org.opencontainers.image.revision="1.0"
