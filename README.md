# OCS2 ROS2 Dockerfile 
This repository is dockerfile for ocs2

# Build
```shell
git clone https://github.com/ZiQingDream/ocs2-ros2-docker.git
cd ocs2-ros2-docker
docker build -t robotics/ocs2:humble .
```

# RUN
1. start terminal and run
```shell
xhost +local:
```

2. start terminal and run
```shell
# start the docker, you will exec bash
docker run -it --rm --name ocs2 --gpus all -v /tmp/.X11-unix:/tmp/.X11-unix -v /dev/dri:/dev/dri -e DISPLAY=$DISPLAY robotics/ocs2:humble

```

3. start panda.sh or legged.sh or cartpole.sh, enjoy