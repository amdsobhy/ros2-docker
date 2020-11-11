#Download base image ubuntu 18.04
FROM ubuntu:18.04

# LABEL about the custom image
LABEL maintainer="asobhy@blackberry.com"
LABEL version="0.2.3"
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

# Build tools needed for building dependencies
RUN apt install -y \
	build-essential \
	bc \
	subversion \
	autoconf \
	libtool-bin \
	libssl-dev \
	zlib1g-dev \
	wget \
	git \
	rsync \
	rename \
	libsqlite3-dev \
	sqlite3 \
	bzip2 \
	libbz2-dev \
	zlib1g-dev \
	openssl \
	libgdbm-dev \
	libgdbm-compat-dev \
	liblzma-dev \
	libreadline-dev \
	libncursesw5-dev \
	libffi-dev \
	uuid-dev

# Install cmake 3.18
RUN cd /opt && \
	wget https://cmake.org/files/v3.18/cmake-3.18.0-Linux-x86_64.sh && \
	yes | sh cmake-3.18.0-Linux-x86_64.sh --prefix=/opt && \
	ln -s /opt/cmake-3.18.0-Linux-x86_64/bin/cmake /usr/local/bin/cmake

# Install Python3.8.0. Building from source since no binary package for this specific version was found.
RUN cd /tmp && \
	wget https://www.python.org/ftp/python/3.8.0/Python-3.8.0.tgz && \
	tar -xf Python-3.8.0.tgz && \
	cd Python-3.8.0 && \
	./configure --enable-optimizations --prefix=/usr && \
	make -j$(nproc) && \
	make altinstall && \
	ln -s /usr/bin/python3.8 /usr/bin/python3 && \
	ln -s /usr/bin/python3.8 /usr/bin/python && \
	rm -r /tmp/Python-3.8.0 && \
	rm  /tmp/Python-3.8.0.tgz

# Install standard ROS 2 development tools
# Install pip packages needed for testing
# Needed to build numpy from source
RUN pip3.8 install \
  	colcon-common-extensions \
  	flake8 \
  	pytest-cov \
  	rosdep \
  	setuptools \
  	vcstool \
	lark-parser \
	numpy \
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
	Cython

WORKDIR /root

# Get ROS 2 code
RUN	mkdir -p ros2_${ROS2DIST}/src && \
	cd ros2_${ROS2DIST} && \
	if [ "${ROS2DIST}" = "rolling" ] ; then BRANCH=master ; else BRANCH=${ROS2DIST} ; fi && \
	wget https://raw.githubusercontent.com/ros2/ros2/${BRANCH}/ros2.repos && \
	vcs import src < ros2.repos

# QNX SDP7.1 should be installed on system before creating an image
# QNX SDP7.1 directory should be named qnx710
# ~/qnx710 directory will have to be copied over to the build context directory
COPY qnx710 /root/qnx710

# Setup host for Cross-compiling for QNX
RUN cd ros2_${ROS2DIST} && \
	git clone https://gitlab.com/qnx/ros2/ros2_qnx.git /tmp/ros2 && \
	rsync -haz /tmp/ros2/* . && \
	rm -rf /tmp/ros2 && \
	./create-stage.sh

RUN cd ros2_${ROS2DIST}/qnx_deps && \
	mkdir src && \
	vcs import src < qnx_deps.repos

WORKDIR /root

RUN cp qnx710/qnxsdp-env.sh qnx710/qnxsdp-env-ros2.sh && \
	echo "\nQNX_STAGE=$HOME/ros2_${ROS2DIST}/qnx_stage/target/qnx7\nQCONF_OVERRIDE=$HOME/qnx710/qconf-override.mk\n\nexport QNX_STAGE QCONF_OVERRIDE\n\necho QNX_STAGE=\$QNX_STAGE\necho QCONF_OVERRIDE=\$QCONF_OVERRIDE" >> qnx710/qnxsdp-env-ros2.sh

RUN echo "INSTALL_ROOT_nto := \$(QNX_STAGE)\nUSE_INSTALL_ROOT = 1" > qnx710/qconf-override.mk

# Welcome Message
COPY .welcome-msg.txt /root/
RUN echo "cat /root/.welcome-msg.txt\n" >> /root/.bashrc

# Setup environment variables
RUN echo "echo \"\nQNX Environment variables are set to:\n\"" >> /root/.bashrc
RUN echo ". /root/qnx710/qnxsdp-env-ros2.sh" >> /root/.bashrc
RUN echo "echo \"\n\"" >> /root/.bashrc
