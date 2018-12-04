FROM ubuntu:16.04

# Install packages
RUN apt-get update && yes "Y" \
    | apt-get install --no-install-recommends \
    curl apt-transport-https python-pip tmux ffmpeg python-tk \
    pandoc texlive-xetex texlive-fonts-recommended python-setuptools \
    xvfb mesa-utils libegl1-mesa libgl1-mesa-glx libglu1-mesa libx11-6 x11-common x11-xserver-utils \
    git g++-multilib terminator\
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean all

# Install some python deps
RUN pip install --upgrade pip
RUN pip install --upgrade graphviz numpy meshcat jupyter timeout-decorator sklearn

# Pull down Drake binaries
RUN curl -o drake.tar.gz https://drake-packages.csail.mit.edu/drake/continuous/drake-latest-xenial.tar.gz && tar -xzf drake.tar.gz -C /opt

# Install drake prereqs
RUN apt-get update \
    && yes "Y" | bash /opt/drake/share/drake/setup/install_prereqs \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean all

# clone underactuated repo
RUN git clone -b contact_force_visualization --single-branch https://github.com/pangtao22/underactuated.git /underactuated

# Source environment of Drake installed to /opt/drake
ENV PYTHONPATH /opt/drake/lib/python2.7/site-packages:$PYTHONPATH
ENV PYTHONPATH /underactuated/src:$PYTHONPATH
ENV ROS_PACKAGE_PATH /drake/share/drake/manipulation/models:/drake/share/drake/examples:$ROS_PACKAGE_PATH
ENV DRAKE_RESOURCE_ROOT /drake/share/drake/
ENV LD_LIBRARY_PATH /drake/lib/:$LD_LIBRARY_PATH

# Install matplotlib here, which needs some C complier.
RUN python -m pip install -U matplotlib

# Setup Jupyter for HTML notebook viewering
COPY ./jupyter_notebook_config.py /root/.jupyter/jupyter_notebook_config.py

# pddlstream
RUN git clone -b master https://github.com/caelan/pddlstream.git /pddlstream
RUN cd /pddlstream && git submodule update --init --recursive
RUN /pddlstream/FastDownward/build.py
ENV PYTHONPATH /pddlstream:$PYTHONPATH

ENV PYTHONPATH /6-881-examples:$PYTHONPATH

# RAI
RUN mkdir /rai
RUN git clone https://github.com/MarcToussaint/rai-python.git /rai/rai-python
RUN git clone https://github.com/MarcToussaint/rai-robotModels.git /rai/rai-robotModels
RUN cd /rai/rai-python \
 && git config --file=.gitmodules submodule.rai.url https://github.com/MarcToussaint/rai.git \
 && git config --file=.gitmodules submodule.rai-robotModels.url https://github.com/MarcToussaint/rai-robotModels.git

RUN cd /rai/rai-python \ 
 && git submodule init \
 && git submodule update

RUN sed -i 's/sudo apt-get/apt-get -y/g' /rai/rai-python/rai/build/generic.mk 

RUN apt-get update     \
 && cd /rai/rai-python \ 
 && make -j1 initUbuntuPackages \
 && apt-get clean all

ENV TERM xterm
RUN cd /rai/rai-python && make -j4

RUN /bin/bash -c "source /rai/rai-python/setupPython.sh"

RUN python3 -m pip install --upgrade pip
RUN python3 -m pip install jupyter

# set the terminator inside the docker container to be a different color
RUN mkdir -p /root/.config/terminator
COPY ./terminator_config /root/.config/terminator/config
