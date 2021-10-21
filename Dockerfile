#Download base image ubuntu 18.04
FROM ubuntu:20.04

# LABEL about the custom image
LABEL maintainer="asobhy@blackberry.com"
LABEL version="0.2.4"
LABEL description="Docker image for building ROS2 for QNX."

# Disable Prompt During Packages Installation
ARG DEBIAN_FRONTEND=noninteractive

# set to the distribution being used by passing it as an argument eg: docker build --build-arg ROS2DIST=foxy -t qnxros2_foxy .
ARG ROS2DIST=$ROS2DIST
ENV ROS2DIST=$ROS2DIST

# Set locale
RUN apt-get clean && apt update && apt install -y locales
RUN locale-gen en_US en_US.UTF-8 && \
	update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 && \
	export LANG=en_US.UTF-8

# Add ROS2 apt repository
RUN apt update && apt install -y curl gnupg2 lsb-release && \
	curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - && \
	sh -c 'echo "deb [arch=$(dpkg --print-architecture)] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2-latest.list'

# Build tools needed for building dependencies
RUN apt update && apt install -y \
	build-essential \
  	git \
  	libbullet-dev \
  	python3-colcon-common-extensions \
  	python3-flake8 \
	python3-pip \
	python3-pytest-cov \
	python3-rosdep \
	python3-setuptools \
	python3-vcstool \
	wget \
	bc \
	subversion \
	autoconf \
	libtool-bin \
	libssl-dev \
	zlib1g-dev \
	rsync \
	rename

# Install standard ROS 2 development tools
# Install pip packages needed for testing
# Needed to build numpy from source
RUN python3 -m pip install -U \
	argcomplete \
	flake8-blind-except \
	flake8-builtins \
	flake8-class-newline \
	flake8-comprehensions \
	flake8-deprecated \
	flake8-docstrings \
	flake8-import-order \
	flake8-quotes \
	pytest-repeat \
	pytest-rerunfailures \
	pytest \
	setuptools \
	importlib-metadata \
	importlib-resources \
	Cython \
	numpy \
	lark-parser

# Install CMake 3.18
RUN cd /opt && sudo wget https://cmake.org/files/v3.18/cmake-3.18.0-Linux-x86_64.sh && \
	sudo mkdir /opt/cmake-3.18.0-Linux-x86_64 && \
	yes | sudo sh cmake-3.18.0-Linux-x86_64.sh --prefix=/opt/cmake-3.18.0-Linux-x86_64 --skip-license && \
	sudo ln -s /opt/cmake-3.18.0-Linux-x86_64/bin/cmake /usr/local/bin/cmake

# Adding user
ARG USER_NAME
ARG GROUP_NAME
ARG USER_ID
ARG GROUP_ID

RUN groupadd --gid ${GROUP_ID} ${GROUP_NAME}
RUN useradd --uid ${USER_ID} --gid ${GROUP_ID} --no-log-init --create-home ${USER_NAME}
WORKDIR /home/${USER_NAME}
USER ${USER_NAME}

# Get ROS 2 code
RUN	mkdir -p ros2_${ROS2DIST}/src && \
	cd ros2_${ROS2DIST} && \
	if [ "${ROS2DIST}" = "rolling" ] ; then BRANCH=master ; else BRANCH=${ROS2DIST} ; fi && \
	wget https://raw.githubusercontent.com/ros2/ros2/${BRANCH}/ros2.repos && \
	vcs import src < ros2.repos

# QNX SDP7.1 should be installed on system before creating an image
# QNX SDP7.1 directory should be named qnx710
# ~/qnx710 directory will have to be copied over to the build context directory
COPY --chown=${USER_NAME}:${GROUP_NAME} qnx710 /home/${USER_NAME}/qnx710

# Setup host for Cross-compiling for QNX
RUN cd ros2_${ROS2DIST} && \
        if [ "${ROS2DIST}" = "rolling" ] ; then BRANCH=master ; else BRANCH=${ROS2DIST} ; fi && \
	git clone -b ${BRANCH} https://gitlab.com/qnx/ros2/ros2_qnx.git /tmp/ros2 && \
	rsync -haz /tmp/ros2/* . && \
	rm -rf /tmp/ros2

# Import QNX dependency repositories
RUN cd ros2_${ROS2DIST} && \
	mkdir -p src/qnx_deps && \
	vcs import src/qnx_deps < qnx_deps.repos

RUN cd ros2_${ROS2DIST} && \
	./patch-pkgxml.py --path=src && \
	./colcon-ignore.sh

WORKDIR /home/${USER_NAME}

CMD /bin/bash

# Welcome Message
COPY --chown=${USER_NAME}:${GROUP_NAME} .welcome-msg.txt /home/${USER_NAME}
RUN echo "cat /home/${USER_NAME}/.welcome-msg.txt\n" >> /home/${USER_NAME}/.bashrc

# Setup environment variables
RUN echo "echo \"\nQNX Environment variables are set to:\n\"" >> /home/${USER_NAME}/.bashrc
RUN echo ". /home/${USER_NAME}/qnx710/qnxsdp-env.sh" >> /home/${USER_NAME}/.bashrc
RUN echo "echo \"\n\"" >> /home/${USER_NAME}/.bashrc
