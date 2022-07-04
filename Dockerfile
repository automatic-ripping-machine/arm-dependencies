###########################################################
# base image, used for build stages and final images
FROM phusion/baseimage:focal-1.2.0 as base
RUN mkdir /opt/arm
WORKDIR /opt/arm

# start by updating and upgrading the OS
RUN \
    apt clean && \
    apt update && \
    apt upgrade -y -o Dpkg::Options::="--force-confold"
# create an arm group(gid 1000) and an arm user(uid 1000), with password logon disabled
RUN groupadd -g 1000 arm \
    && useradd -rm -d /home/arm -s /bin/bash -g arm -G video,cdrom -u 1000 arm

# set the default environment variables
# UID and GID are not settable as of https://github.com/phusion/baseimage-docker/pull/86, as doing so would
# break multi-account containers
ENV ARM_UID=1000
ENV ARM_GID=1000

# setup gnupg/wget for add-ppa.sh
RUN install_clean \
        git \
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
        vim \
        # arm extra requirements
        scons swig libzbar-dev libzbar0

# add the PPAs we need, using add-ppa.sh since add-apt-repository is unavailable
COPY ./scripts/add-ppa.sh /root/add-ppa.sh
RUN bash /root/add-ppa.sh ppa:mc3man/focal6

###########################################################
# install deps specific to the docker deployment
FROM base as deps-docker
RUN install_clean gosu

VOLUME /home/arm/Music
VOLUME /home/arm/logs
VOLUME /home/arm/media
VOLUME /etc/arm/config


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

FROM phusion/baseimage:focal-1.2.0 as build
# /usr/local/bin/HandBrakeCLI
# install makemkv and handbrake
#RUN apt update && install_clean handbrake-cli
COPY ./scripts/install_handbrake.sh /install_handbrake.sh
RUN chmod +x /install_handbrake.sh && sleep 1 && \
    /install_handbrake.sh

# MakeMKV setup by https://github.com/tianon
COPY ./scripts/install_makemkv.sh /install_makemkv.sh
RUN chmod +x /install_makemkv.sh && sleep 1 && \
    /install_makemkv.sh
# clean up apt
RUN apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

###########################################################
# Final image pushed for use
FROM deps-ripper as arm-dependencies
# Copy in HandBrakeCLI
COPY --from=build /usr/local/bin/HandBrakeCLI /usr/local/bin/HandBrakeCLI
# Copy in MakeMKV requirments
COPY --from=build /usr/local/bin/makemkvcon /usr/local/bin/makemkvcon
COPY --from=build /usr/local/bin/makemkv /usr/local/bin/makemkv
COPY --from=build /usr/local/share/MakeMKV/appdata.tar /usr/local/share/MakeMKV/appdata.tar
COPY --from=build /usr/local/lib/libmakemkv.so.1 /usr/local/lib/libmakemkv.so.1
COPY --from=build /usr/local/lib/ /usr/local/lib/

# Container healthcheck
COPY scripts/healthcheck.sh /healthcheck.sh
RUN chmod +x /healthcheck.sh
HEALTHCHECK --interval=5m --timeout=15s --start-period=30s CMD /healthcheck.sh

ARG VERSION
ARG BUILD_DATE
# set metadata
LABEL org.opencontainers.image.source=https://github.com/1337-server/arm-dependencies.git
LABEL org.opencontainers.image.url=https://github.com/1337-server/arm-dependencies
LABEL org.opencontainers.image.description="Dependencies for Automatic ripping machine"
LABEL org.opencontainers.image.documentation=https://raw.githubusercontent.com/1337-server/arm-dependencies/main/README.md
LABEL org.opencontainers.image.license=MIT
LABEL org.opencontainers.image.version=$VERSION
LABEL org.opencontainers.image.created=$BUILD_DATE
