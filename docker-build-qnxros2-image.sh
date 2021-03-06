#!/bin/bash

if [ -z "$1" ]; then
	echo "Please run the script with the name of the distribution as an argument e.g: ./docker-build-image.sh foxy"
	exit 1
fi

if [ ! -d $PWD/qnx710 ]; then
	echo "copy QNX SDP into the build context directory"
	exit 1
fi

docker build -t qnxros2_${1} \
  --build-arg ROS2DIST=${1} \
  --build-arg USER_NAME=$(id --user --name) \
  --build-arg GROUP_NAME=$(id --group --name) \
  --build-arg USER_ID=$(id --user) \
  --build-arg GROUP_ID=$(id --group) .