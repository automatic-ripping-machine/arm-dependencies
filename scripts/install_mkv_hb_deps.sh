#!/bin/bash

# This script installs dependencies used by the install_makemkv.sh and install_handbrake.sh scripts
echo -e "${RED}Installing build dependencies for MakeMKV and HandBrakeCLI${NC}"

apt update && apt upgrade -yq

# makemkv deps
apt install -yq --no-install-recommends openjdk-11-jre-headless
apt install -yq --no-install-recommends ca-certificates g++ gcc gnupg dirmngr libavcodec-dev libexpat-dev libssl-dev make pkg-config qtbase5-dev wget zlib1g-dev


# handbrake deps
# if architecture is any flavor of arm, install standard HandBrakeCLI and exit cleanly
if [[ $(dpkg --print-architecture) =~ arm.* ]]; then
    echo "Running on arm - using apt for HandBrakeCLI"
    apt install -yqq handbrake-cli
    cp /usr/bin/HandBrakeCLI /usr/local/bin/HandBrakeCLI
    exit 0
fi

apt install -yq autoconf automake autopoint appstream build-essential cmake git libass-dev libbz2-dev libfontconfig1-dev libfreetype6-dev libfribidi-dev libharfbuzz-dev libjansson-dev liblzma-dev libmp3lame-dev libnuma-dev libogg-dev libopus-dev libsamplerate-dev libspeex-dev libtheora-dev libtool libtool-bin libturbojpeg0-dev libvorbis-dev libx264-dev libxml2-dev libvpx-dev m4 make meson nasm ninja-build patch pkg-config tar zlib1g-dev clang libavcodec-dev  libva-dev libdrm-dev


################################################
# begin modified deps

# modified Handbrake deps for Intel QSV support

# install Intel GPU repository for GPU driver and support libs
#
wget -qO - https://repositories.intel.com/gpu/intel-graphics.key | \
  gpg --yes --dearmor --output /usr/share/keyrings/intel-graphics.gpg
echo "deb [arch=amd64,i386 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu jammy client" | \
  tee /etc/apt/sources.list.d/intel-gpu-jammy.list

apt update && apt upgrade -yq

# install OneVPL Compute Runtime, Media, and Mesa packages, misc utils
# for 11th+ Gen Intel Core Processor with UHD integrated
# and Intel ARC graphics family 
# from https://dgpu-docs.intel.com/driver/client/overview.html
# 
# One VPL may work with earlier Gen Processor/UHD

apt install -yq \
  intel-opencl-icd intel-level-zero-gpu level-zero intel-level-zero-gpu-raytracing \
  intel-media-va-driver-non-free libmfx1 libmfxgen1 libvpl2 \
  libegl-mesa0 libegl1-mesa libegl1-mesa-dev libgbm1 libgl1-mesa-dev libgl1-mesa-dri \
  libglapi-mesa libgles2-mesa-dev libglx-mesa0 libigdgmm12 libxatracker2 mesa-va-drivers \
  mesa-vdpau-drivers mesa-vulkan-drivers va-driver-all vainfo hwinfo clinfo 

# install Intel GPU QSV support per Handbrake website
apt install -yq libva-dev libdrm-dev

# install intel GPU tools/utils including intel_gpu_top for character GPU utilization display for debug
apt install -yq intel-gpu-tools  

# install intel media stack runtime for older processor/integrated GPU support 
# from https://github.com/Intel-Media-SDK/MediaSDK/wiki/Intel-media-stack-on-Ubuntu
#
# it has been reported this media stack may successfully co-exist with OneVPL
# 
# The OneVPL Dispatcher loads either the Media-SDK Legacy Runtime or VPL Runtime depending on the platform

# such support is beyond this work and has not specifically been enable or tested
#
# uncomment the following 3 lines to install Media-SDK support - this is untested with OneVPL in this specific application

# apt install -yq libmfx1 libmfx-tools
# apt-get install -yq libva-drm2 libva-x11-2 libva-wayland2 libva-glx2
# export LIBVA_DRIVER_NAME=iHD


# install Handbrake 1.9.x deps (for latest dev) - from Handbrake website
# for the most part this matches default ARM handbrake deps above - duplicate packages are skipped (being already installed above), additional packages are installed

apt install -yq autoconf automake build-essential cmake git libass-dev libbz2-dev libfontconfig-dev libfreetype-dev libfribidi-dev libharfbuzz-dev libjansson-dev liblzma-dev libmp3lame-dev libnuma-dev libogg-dev libopus-dev libsamplerate0-dev libspeex-dev libtheora-dev libtool libtool-bin libturbojpeg0-dev libvorbis-dev libx264-dev libxml2-dev libvpx-dev m4 make meson nasm ninja-build patch pkg-config tar zlib1g-dev

# install 1.9.x GTK-4 GUI deps (for latest dev) - from HandBrake website - perhaps needed to support use of custom presets exported from HandBrake GUI for use in Handbrake CLI

apt install -yq appstream desktop-file-utils gettext gstreamer1.0-libav gstreamer1.0-plugins-good libgstreamer-plugins-base1.0-dev libgtk-4-dev

# end modified Handbrake deps for Intel QSV support

# end modified deps
################################################

# cleanup
apt autoremove
apt clean
rm -r /var/lib/apt/lists/*
