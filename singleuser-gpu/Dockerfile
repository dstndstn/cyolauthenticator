FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt -yq dist-upgrade && \
    apt install -yq --no-install-recommends apt-utils && \
    apt install -yq --no-install-recommends \
    htop \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
    run-one \
    openssh-client libssl-dev \
    python3-pip \
    python3.8 python3.8-dev \
    gnupg policycoreutils imagemagick curl vim \
    iputils-ping git less \
    patch gcc make libc6-dev \
    nfs-common rpcbind libnss-ldap ldap-utils ldap-auth-config \
    libpam-ldap \
    libbz2-dev \
    software-properties-common \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

# Make python3.8 the default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.8 1

RUN python -m pip install --no-cache-dir setuptools && \
    python -m pip install --no-cache-dir \
    oauthenticator==0.9.0 \
    jupyter==1.0.0 \
    jupyterhub==1.0.0 \
    python-oauth2==1.1.1 \
    notebook==6.0.2 \
    matplotlib numpy scipy scikit-learn asdf h5py cython
RUN python -m pip install --no-cache-dir tensorflow

# Add NVIDIA package repositories -- https://www.tensorflow.org/install/gpu
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin \
 && mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600 \
 && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub \
 && add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/ /" \
 && apt update \
 && wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb \
 && apt install -y ./nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb \
 && apt update \
 && apt install -y --no-install-recommends \
  cuda-cudart-11-6 \
  cuda-nvrtc-11-6 \
  libcufft-11-6 \
  libcurand-11-6 \
  libcusolver-11-6 \
  libcusparse-11-6 \
  libcudnn8 \
  libcudnn8-dev \
  libnvinfer7 \
  libnvinfer-plugin7 \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

# Jupyterhub / Google cloud setup

COPY nsswitch.conf /etc
COPY etcldap.conf /etc/ldap.conf

RUN echo "libpam-runtime libpam-runtime/profiles multiselect unix, ldap" | debconf-set-selections && \
    dpkg-reconfigure libpam-runtime

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

ENV SHELL=/bin/bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

EXPOSE 8888
CMD ["start-notebook.sh"]

# From https://github.com/jupyter/docker-stacks
COPY start-notebook.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /etc/jupyter/

# Google mounts the NVIDIA drivers already!  In /usr/local/nvidia
ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib64:/usr/local/cuda-11.6/lib64
ENV PATH=${PATH}:/usr/local/nvidia/bin
