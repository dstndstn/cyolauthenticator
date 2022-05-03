FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt -yq dist-upgrade && \
  apt install -yq --no-install-recommends \
    apt-utils && \
  apt install -yq --no-install-recommends \
    htop \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
    run-one \
    openssh-client \
    libssl-dev \
    python3-pip \
    python3.8 \
    python3.8-dev \
    gnupg \
    policycoreutils \
    imagemagick \
    curl \
    vim \
    nano \
    iputils-ping \
    git \
    less \
    patch \
    gcc \
    make \
    libc6-dev \
    nfs-common \
    rpcbind \
    libnss-ldap \
    ldap-utils \
    ldap-auth-config \
    libpam-ldap \
    libbz2-dev \
    software-properties-common \
    \
    build-essential \
    file \
    g++ \
    gfortran \
    hdf5-tools \
    libboost-all-dev \
    libfftw3-dev \
    libgsl-dev \
    libhdf5-dev \
    libhwloc-dev \
    libopenblas-dev \
    libopenmpi-dev \
    libpetsc-real-dev \
    libudev-dev \
    perl \
    pkg-config \
    rsync \
    subversion \
    zlib1g-dev \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

# Make python3.8 the default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.8 1

RUN python -m pip install --no-cache-dir \
    setuptools && \
  python -m pip install --no-cache-dir \
    \
    oauthenticator==0.9.0 \
    jupyter==1.0.0 \
    jupyterhub==1.0.0 \
    python-oauth2==1.1.1 \
    notebook==6.0.2 \
    \
    jupyterlab \
    matplotlib \
    numpy \
    scipy \
    scikit-learn \
    asdf \
    h5py \
    cython \
    requests
RUN python -m pip install --no-cache-dir tensorflow

# Add NVIDIA package repositories -- https://www.tensorflow.org/install/gpu
# RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin \
#  && mv cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600 \
#  && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub \
#  && add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/ /" \
#  && apt update \
#  && wget http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb \
#  && apt install -y ./nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb \
#  && apt update \
#  && apt install -y --no-install-recommends \
#   cuda-cudart-11-5 \
#   cuda-nvrtc-11-5 \
#   cuda-nvcc-11-5 \
#   cuda-nvprof-11-6 \
#   libcufft-11-5 \
#   libcurand-11-5 \
#   libcurand-dev-11-6 \
#   libcusolver-11-5 \
#   libcusparse-11-5 \
#   libcudnn8 \
#   libcudnn8-dev \
#   libnvinfer7 \
#   libnvinfer-plugin7 \
#  && apt clean \
# && rm -rf /var/lib/apt/lists/*

# Add NVIDIA package repositories -- https://www.tensorflow.org/install/gpu

ADD https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb .
ADD https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu2004/x86_64/nvidia-machine-learning-repo-ubuntu2004_1.0.0-1_amd64.deb .
RUN dpkg -i cuda-keyring_1.0-1_all.deb \
 && apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu2004/x86_64/7fa2af80.pub \
 && dpkg -i nvidia-machine-learning-repo-ubuntu2004_1.0.0-1_amd64.deb \
 && wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin \
 && mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600

RUN apt update \
 && apt install -y --no-install-recommends \
  cuda-cudart-11-5 \
  cuda-nvrtc-11-5 \
  cuda-nvcc-11-5 \
  cuda-nvprof-11-5 \
  cuda-toolkit-11-5-config-common \
  libcublas-11-5 \
  libcufft-11-5 \
  libcurand-11-5 \
  libcurand-dev-11-5 \
  libcusolver-11-5 \
  libcusparse-11-5 \
  libcudnn8-dev \
  libnvinfer8 \
  libnvinfer-plugin8 \
 && apt clean \
 && rm -rf /var/lib/apt/lists/*

#  libnvinfer7 \
#  libnvinfer-plugin7 \

# Google mounts the NVIDIA drivers already!  In /usr/local/nvidia
ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib64:/usr/local/cuda/lib64 \
    PATH=${PATH}:/usr/local/nvidia/bin:/usr/local/cuda/bin

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

ENV JUPYTER_ENABLE_LAB=1

# WORKDIR /usr/local
# #ARG GH_TOKEN
# COPY install-gh.sh .
# RUN bash ./install-gh.sh
WORKDIR /usr/local
RUN git clone https://github.com/openPMD/openPMD-api.git

COPY spack-cfg2.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/spack-cfg2.sh
WORKDIR /usr/carpetx-spack
RUN chmod 755 /usr/carpetx-spack
# Install all carpetx dependencies and create local.cfg
RUN bash /usr/local/bin/spack-cfg2.sh










#### ERIK
#  
# 
# # Install cmake
# # We need a modern cmake to build AMReX
# RUN mkdir dist && \
#   (cd dist && \
#   wget https://github.com/Kitware/CMake/releases/download/v3.21.2/cmake-3.21.2-linux-x86_64.tar.gz && \
#   tar xzf cmake-3.21.2-linux-x86_64.tar.gz && \
#   rsync -r cmake-3.21.2-linux-x86_64/ /usr/local && \
#   true) && \
#   rm -rf dist
# 
# # Install ADIOS2
# # ADIOS2 is a parallel I/O library, comparable to HDF5
# RUN mkdir src && \
#   (cd src && \
#   wget https://github.com/ornladios/ADIOS2/archive/refs/tags/v2.7.1.tar.gz && \
#   tar xzf v2.7.1.tar.gz && \
#   cd ADIOS2-2.7.1 && \
#   mkdir build && \
#   cd build && \
#   cmake .. && \
#   make -j$(nproc) && \
#   make -j$(nproc) install && \
#   true) && \
#   rm -rf src
# 
# # Install NSIMD
# # NSIMD allows writing explicitly SIMD-vectorized code
# # Note: This assumes that the system has x86_64 CPUs with AVX2
# RUN mkdir src && \
#     (cd src && \
#     wget https://github.com/agenium-scale/nsimd/archive/refs/tags/v3.0.1.tar.gz && \
#     tar xzf v3.0.1.tar.gz && \
#     cd nsimd-3.0.1 && \
#     mkdir build && \
#     cd build && \
#     cmake \
#         -DCMAKE_BUILD_TYPE=RelWithDebInfo \
#         -DCMAKE_C_COMPILER=gcc \
#         -DCMAKE_CXX_COMPILER=g++ \
#         -Dsimd=AVX2 \
#         -DCMAKE_INSTALL_PREFIX=/usr/local \
#         .. && \
#     make -j$(nproc) && \
#     make -j$(nproc) install && \
#     true) && \
#     rm -rf src
# 
# # Install openPMD-api
# # openPMD-api defines a standard for laying out AMR data in a file
# # - Depends on ADIOS2
# RUN mkdir src && \
#     (cd src && \
#     wget https://github.com/openPMD/openPMD-api/archive/refs/tags/0.14.4.tar.gz && \
#     tar xzf 0.14.4.tar.gz && \
#     cd openPMD-api-0.14.4 && \
#     mkdir build && \
#     cd build && \
#     cmake .. && \
#     make -j$(nproc) && \
#     make -j$(nproc) install && \
#     true) && \
#     rm -rf src
# 
# # Install Silo
# # openPMD-api defines a standard for laying out AMR data in a file
# RUN mkdir src && \
#     (cd src && \
#     wget https://github.com/LLNL/Silo/releases/download/v4.11/silo-4.11.tar.gz && \
#     tar xzf silo-4.11.tar.gz && \
#     cd silo-4.11 && \
#     mkdir build && \
#     cd build && \
#     ../configure \
#         --disable-fortran \
#         --enable-optimization \
#         --with-hdf5=/usr/lib/x86_64-linux-gnu/hdf5/serial/include,/usr/lib/x86_64-linux-gnu/hdf5/serial/lib \
#         --prefix=/usr/local && \
#     make -j$(nproc) && \
#     make -j$(nproc) install && \
#     true) && \
#     rm -rf src
# 
# # Install ssht
# # ssht provides spin-weighted spherical harmonicsa
# RUN mkdir src && \
#     (cd src && \
#     wget https://github.com/astro-informatics/ssht/archive/v1.5.1.tar.gz && \
#     tar xzf v1.5.1.tar.gz && \
#     cd ssht-1.5.1 && \
#     mkdir build && \
#     cd build && \
#     cmake .. && \
#     make -j$(nproc) && \
#     make -j$(nproc) install && \
#     true) && \
#     rm -rf src
# 
# # Install yaml-cpp
# # yaml-cpp allows reading and writing YAML files
# RUN mkdir src && \
#     (cd src && \
#     wget https://github.com/jbeder/yaml-cpp/archive/yaml-cpp-0.6.3.tar.gz && \
#     tar xzf yaml-cpp-0.6.3.tar.gz && \
#     cd yaml-cpp-yaml-cpp-0.6.3 && \
#     mkdir build && \
#     cd build && \
#     cmake .. && \
#     make -j$(nproc) && \
#     make -j$(nproc) install && \
#     true) && \
#     rm -rf src
# 
# # Install AMReX
# # AMReX provides adaptive mesh refinement
# # - Enable Fortran for `docker/Dockerfile`
# # - Keep AMReX source tree around for debugging
# # - Install this last because it changes most often
# # - Optimize AMReX, since otherwise CUDA code generation takes too long
# RUN mkdir src && \
#     (cd src && \
#     wget https://github.com/AMReX-Codes/amrex/archive/22.04.tar.gz && \
#     tar xzf 22.04.tar.gz && \
#     cd amrex-22.04 && \
#     mkdir build && \
#     cd build && \
#     cmake \
#         -DCMAKE_BUILD_TYPE=RelWithDebInfo \
#         -DAMReX_GPU_BACKEND=CUDA \
#         -DAMReX_CUDA_ARCH=7.5 \
#         -DAMReX_OMP=ON \
#         -DAMReX_PARTICLES=ON \
#         -DCMAKE_INSTALL_PREFIX=/usr/local \
#         .. && \
#     make -j$(nproc) && \
#     make -j$(nproc) install && \
#     true)
# 
