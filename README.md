# arm-dependencies

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/shitwolfymakes/arm-dependencies/publish-image)](https://github.com/shitwolfymakes/arm-dependencies/actions/workflows/publish-image.yml)
[![Docker](https://img.shields.io/docker/pulls/shitwolfymakes/arm-dependencies.svg)](https://hub.docker.com/r/shitwolfymakes/arm-dependencies)

[![GitHub license](https://img.shields.io/github/license/shitwolfymakes/arm-dependencies)](https://github.com/shitwolfymakes/arm-dependencies/blob/main/LICENSE)
[![GitHub forks](https://img.shields.io/github/forks/shitwolfymakes/arm-dependencies)](https://github.com/shitwolfymakes/arm-dependencies/network)
[![GitHub stars](https://img.shields.io/github/stars/shitwolfymakes/arm-dependencies)](https://github.com/shitwolfymakes/arm-dependencies/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/shitwolfymakes/arm-dependencies)](https://github.com/shitwolfymakes/arm-dependencies/issues)
[![GitHub pull requests](https://img.shields.io/github/issues-pr/shitwolfymakes/arm-dependencies)](https://github.com/shitwolfymakes/arm-dependencies/pulls)

![PyPI - Python Version](https://img.shields.io/pypi/pyversions/django)

[![Discord](https://img.shields.io/discord/576479573886107699)](https://discord.gg/BCarpwC7qC)

## Overview
This repo codifies the requirements for building and running Automatic Ripping Machine, and provides a docker container that has everything preinstalled. All you need to do is install the ARM source and set up files.

The `arm-dependencies`Docker image is rebuilt every night, so you should always get the most up-to-date versions of MakeMKV and Handbrake when you build ARM from this image.


## Usage
### Git Repo
To add this manually, run the following command:
```shell
git submodule add -b main https://github.com/shitwolfymakes/arm-dependencies arm-dependencies
git submodule update --init --recursive
git config -f .gitmodules submodule.arm-dependencies.update rebase
git submodule update --remote
```

In your fork's `requirements.txt`, replace everything with
```text
-r arm-dependencies/requirements.txt
```

### Docker Container
To base your docker container on `arm-dependencies`, add this to the top of your `Dockerfile`:
```dockerfile
FROM shitwolfymakes/arm-dependencies AS base
```

To start the rsyslog service included in this container, add the following command before the command to run `armui.py` in your `Dockerfile`:
```dockerfile
CMD service rsyslog start
```
