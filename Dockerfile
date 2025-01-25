FROM ubuntu:22.04

# 获取并正确更换系统的源为国内源
# https: apt install -y apt-transport-https ca-certificates
RUN mv /etc/apt/sources.list /etc/apt/sources.list.bk && rm -rf /etc/apt/sources.list.d/* \
    && VERSION_CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d'=' -f2) \
    && echo "deb http://mirrors.ustc.edu.cn/ubuntu/ $VERSION_CODENAME main restricted universe multiverse" > /etc/apt/sources.list \
    && echo "deb http://mirrors.ustc.edu.cn/ubuntu/ $VERSION_CODENAME-security main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.ustc.edu.cn/ubuntu/ $VERSION_CODENAME-updates main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.ustc.edu.cn/ubuntu/ $VERSION_CODENAME-backports main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "" >> /etc/apt/sources.list

# 设置时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo 'Asia/Shanghai' > /etc/timezone

# 设置语言，否则安装ros会卡在设置语言环境
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"

RUN apt-get update \
    && apt -y install locales wget python3-yaml \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && echo "chooses:\n" > fish_install.yaml \
    && echo "- {choose: 1, desc: '一键安装:ROS(支持ROS和ROS2,树莓派Jetson)'}\n" >> fish_install.yaml \
    && echo "- {choose: 1, desc: 更换源继续安装}\n" >> fish_install.yaml \
    && echo "- {choose: 2, desc: 清理三方源}\n" >> fish_install.yaml \
    && echo "- {choose: 1, desc: humble(ROS2)}\n" >> fish_install.yaml \
    && echo "- {choose: 1, desc: humble(ROS2)桌面版}\n" >> fish_install.yaml \
    && wget http://fishros.com/install  -O fishros && /bin/bash fishros && rm -rf fishros \
    && rm -rf /var/lib/apt/lists/*  /tmp/* /var/tmp/* \
    && apt-get clean && apt autoclean 

# 安装rosdepc，这里没有使用一键安装
RUN apt-get update \
    && apt-get install -y python3-pip \
    && pip install rosdepc \
    && bash -c "source /opt/ros/humble/setup.bash && rosdepc init && rosdepc update"

# 安装ocs2_ros2，这里使用rosdepc安装依赖，并且限制构建线程数
ARG PROJECT_NAME=ocs2_ros2

WORKDIR /root/$PROJECT_NAME
RUN --mount=type=bind,source=depends,target=/root/depends \
    apt-get update && apt-get install -y git vim gnome-terminal dbus-x11 \
    && git clone https://github.com/legubiao/ocs2_ros2 src \
    && cd /root/$PROJECT_NAME/src \
    && git submodule update --init --recursive \
    && git apply /root/depends/hpp-fcl.patch \
    && cd /root/$PROJECT_NAME \ 
    && bash -c "source /opt/ros/humble/setup.bash && rosdepc install --from-paths src --ignore-src -r -y" \
    && bash -c "source /opt/ros/humble/setup.bash \
        && colcon build --symlink-install --cmake-args=-DCMAKE_BUILD_TYPE=Release --parallel-workers 12 \
        --packages-ignore ocs2_ballbot_mpcnet ocs2_legged_robot_mpcnet ocs2_mpcnet_core ocs2_legged_robot_raisim ocs2_raisim_core"

RUN echo "#!/bin/bash" >cartpole.sh \
    && echo "source ./install/local_setup.bash" >>cartpole.sh \
    && echo "ros2 launch ocs2_cartpole_ros cartpole.launch.py" >>cartpole.sh \
    && chmod a+x cartpole.sh \
    && echo "#!/bin/bash" >panda.sh \
    && echo "source ./install/local_setup.bash" >>panda.sh \
    && echo "ros2 launch ocs2_mobile_manipulator_ros manipulator_franka.launch.py" >>panda.sh \
    && chmod a+x panda.sh \
    && echo "#!/bin/bash" >legged.sh \
    && echo "source ./install/local_setup.bash" >>legged.sh \
    && echo "ros2 launch ocs2_legged_robot_ros legged_robot_ddp.launch.py" >>legged.sh \
    && chmod a+x legged.sh

RUN apt-get clean && rm -rf /var/lib/apt/lists/*