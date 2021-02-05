#!/bin/bash

if [ -z "$1" ]; then
	echo "Please run the script with the name of the distribution as an argument e.g: ./docker-build-image.sh foxy"
	exit 1
fi

if [ ! -d $PWD/qnx710 ]; then
	echo "copy QNX SDP into the build context directory"
	exit 1
fi

docker build --build-arg ROS2DIST=${1} -t qnxros2_${1} .
