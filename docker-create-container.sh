#!/bin/bash

if [ -z "$1" ]; then
	echo "Please run the script with the name of the distribution as an argument e.g: ./docker-build-image.sh foxy"
	exit 1
fi

docker run -it \
  --net=host \
  --privileged \
  -v ~/.vimrc:$HOME/.vimrc \
  -v ~/.ssh:$HOME/.ssh \
  -v ~/.qnx:$HOME/.qnx \
  -v ~/shared:$HOME/shared \
  -v $HOME/.qnx:$HOME/.qnx \
  "qnxros2_$1:latest" /bin/bash