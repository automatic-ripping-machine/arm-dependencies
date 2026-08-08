#!/bin/bash
#
# install_intel_qsv_deps.sh
#
# Purpose:
#   Ubuntu 22.04 (Jammy)'s default apt repositories cap the VA-API stack
#   (libva / intel-media-va-driver-non-free) at VA-API 1.14. Recent
#   HandBrake releases (built with recent FFmpeg/libavcodec) require
#   VA-API >= 1.15 to initialise a QSV hwdevice. Without this, QSV
#   transcodes fail at runtime with:
#
#     libva: This version of libva doesn't support retrieving the device
#     information from the driver. Please consider to upgrade libva to
#     support VA-API 1.15.0
#
#   even though `vainfo` and driver loading (`va_openDriver`) succeed.
#
#   This script adds Intel's official GPU package repository, which
#   ships a matched set of libva / intel-media-va-driver-non-free /
#   libmfx / libvpl packages built against a current VA-API version.
#   Both runtime and -dev packages are installed so that HandBrake,
#   built afterwards in install_handbrake.sh, links against and is
#   compiled with the correct VA-API version checks.
#
#   See: https://github.com/automatic-ripping-machine/automatic-ripping-machine/issues/909
#        https://github.com/automatic-ripping-machine/automatic-ripping-machine/issues/1522
#        https://github.com/automatic-ripping-machine/automatic-ripping-machine/issues/1668
#        https://dgpu-docs.intel.com/installation-guides/installing-packages-from-the-intel-ppa.html
#
# Notes:
#   - This only affects Intel iGPU/dGPU (QSV) hosts. It has no effect on
#     systems without Intel graphics hardware, but the packages are
#     harmless to install regardless of host GPU vendor.
#   - Must run BEFORE install_handbrake.sh so that HandBrake's ./configure
#     step detects the updated libva-dev/libmfx-dev headers at build time.

set -euo pipefail

echo "Adding Intel GPU package repository (for QSV / VA-API support)..."

apt-get update
apt-get install -y --no-install-recommends wget gnupg

wget -qO /tmp/intel-graphics.key https://repositories.intel.com/gpu/intel-graphics.key
gpg --yes --dearmor --output /usr/share/keyrings/intel-graphics.gpg /tmp/intel-graphics.key
rm -f /tmp/intel-graphics.key

echo "deb [arch=amd64,i386 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu jammy unified" \
    > /etc/apt/sources.list.d/intel-gpu-jammy.list

apt-get update

echo "Installing Intel VA-API / QSV runtime and development packages..."

# Runtime packages: required at container run-time for QSV to function
# Development packages (-dev): required at *build* time so HandBrake's
# ./configure correctly detects VA-API >= 1.15 support (VA_CHECK_VERSION)
apt-get install -y --no-install-recommends \
    intel-media-va-driver-non-free \
    libmfx-gen1.2 \
    libvpl2 \
    libva-glx2 \
    va-driver-all \
    vainfo \
    libva-dev \
    libmfx-dev

echo "Intel QSV/VA-API dependencies installed successfully."
