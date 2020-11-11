# ros-dockerfiles

This repository contain the files needed to generate a docker image for building ROS2 for QNX.

Steps:

1- Clone the repo locally

2- rsync SDP7.1 directory into cloned directory

3- run the script:

./docker-build-qnxros2-image.sh <ros2-distro>

where <ros2-distro> is for example "foxy"

4- After done and you run a container from the image, please follow the rest of the instructions displayed in the welcome message.
