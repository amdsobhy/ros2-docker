#!/bin/bash

if [ -z "$1" ]; then
	echo "Please run the script with the name of the distribution as an argument e.g: ./docker-build-image.sh foxy"
	exit 1
fi

docker run -it \
  -v $HOME/.qnx:$HOME/.qnx \
  qnxros2_$1:latest /bin/bash