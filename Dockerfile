FROM ubuntu:20.04

LABEL maintainer="asobhy@blackberry.com"
LABEL version="0.2.4"
LABEL description="Docker image for building ROS2 for QNX."

# Disable Prompt During Package Installation
ARG DEBIAN_FRONTEND=noninteractive

# Set to the distribution being used by passing it as an argument eg: docker build --build-arg ROS2DIST=foxy -t qnxros2_foxy .
ARG ROS2DIST=$ROS2DIST
ENV ROS2DIST=$ROS2DIST

# Add user
ARG USER_NAME
ARG GROUP_NAME
ARG USER_ID
ARG GROUP_ID
RUN groupadd --gid ${GROUP_ID} ${GROUP_NAME} && \
	useradd --uid ${USER_ID} --gid ${GROUP_ID} --groups sudo --no-log-init --create-home ${USER_NAME} && \
	echo "${USER_NAME}:password" | chpasswd

# QNX SDP7.1 should be installed on system before creating an image
# QNX SDP7.1 directory should be named qnx710
# ~/qnx710 directory will have to be copied over to the build context directory
COPY --chown=${USER_NAME}:${GROUP_NAME} qnx710 /home/${USER_NAME}/qnx710

# Set locale
RUN apt-get update && apt-get install -y locales && \
	rm -rf /var/lib/apt/lists/* && \
	locale-gen en_US en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# Add ROS2 apt repository
RUN apt-get update && apt-get install -y curl gnupg2 lsb-release && \
	rm -rf /var/lib/apt/lists/* && \
	curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - && \
	sh -c 'echo "deb [arch=$(dpkg --print-architecture)] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2-latest.list'

# Build tools needed for building dependencies
RUN apt-get update && apt-get install -y \
	bison \
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
	rename \
	&& rm -rf /var/lib/apt/lists/*

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
RUN cd /opt && wget https://cmake.org/files/v3.18/cmake-3.18.0-Linux-x86_64.sh && \
	mkdir /opt/cmake-3.18.0-Linux-x86_64 && \
	yes | sh cmake-3.18.0-Linux-x86_64.sh --prefix=/opt/cmake-3.18.0-Linux-x86_64 --skip-license && \
	sudo ln -s /opt/cmake-3.18.0-Linux-x86_64/bin/cmake /usr/local/bin/cmake

# Development Tools
RUN apt-get update && apt-get install -y vim

# Change to non-root user to set up home directory
WORKDIR /home/${USER_NAME}
USER ${USER_NAME}

# Build CycloneDDS tools
RUN git clone https://github.com/eclipse-cyclonedds/cyclonedds.git && \
	cd cyclonedds && \
	git checkout 6e16753f971049061a27fd70c70e2d780ff321ef && \
	mkdir build && \
	cd build && \
	cmake .. && \
	cmake --build . --target ddsconf idlc && \
	echo "export DDSCONF_EXE=$(find ~/cyclonedds -type f -name ddsconf)" >> /home/${USER_NAME}/.bashrc && \
	echo "export IDLC_EXE=$(find ~/cyclonedds -type f -name idlc)" >> /home/${USER_NAME}/.bashrc 

# Get ROS 2 code
RUN	mkdir -p ros2_${ROS2DIST}/src && \
	cd ros2_${ROS2DIST} && \
	if [ "${ROS2DIST}" = "rolling" ] ; then BRANCH=master ; else BRANCH=${ROS2DIST} ; fi && \
	wget https://raw.githubusercontent.com/ros2/ros2/${BRANCH}/ros2.repos && \
	vcs import src < ros2.repos

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

# Clone empty ROS2 package workspace
RUN git clone https://gitlab.com/qnx/ros2/dev_ws

# Setup session
COPY --chown=${USER_NAME}:${GROUP_NAME} .session-setup.sh /home/${USER_NAME}
RUN echo "source /home/${USER_NAME}/.session-setup.sh" >> /home/${USER_NAME}/.bashrc

CMD /bin/bash