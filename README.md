# ROS2 QNX Dockerfiles

This repository contain the files needed to generate a docker image for building ROS2 for QNX.
A more in-depth guide can be found on our [readthedocs page](https://ros2-qnx-documentation.readthedocs.io).

## Steps:

1- Clone the repository locally.

2- Run rsync to copy the QNX 7.1 SDP directory into the git repository directory.

3- Run the build script as follows.

```
./docker-build-qnxros2-image.sh [ROS2_DISTRO]
```

For example, `[ROS2_Distro]` can be `foxy`.

4- Create a container with the run script as follows.

```
./docker-create-container.sh [ROS2_DISTRO]
```

5- Follow the rest of the instructions displayed in the welcome message.
