FROM ubuntu:18.04

# TensorFlow version is tightly coupled to CUDA and cuDNN so it should be selected carefully
ENV TENSORFLOW_VERSION=2.1.0
ENV PYTHON_VERSION=3.7.6
ENV TFCPU=1
SHELL ["/bin/bash", "-cu"]

# RUN alias cmd
RUN echo alias ll='ls -all -h' >> ~/.bashrc
RUN echo alias cls='printf "\033c"' >> ~/.bashrc
RUN source ~/.bashrc

# RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends apt-utils
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install --assume-yes --no-install-recommends apt-utils

RUN apt-get install -y bzip2 libbz2-dev zlib1g-dev libssl-dev openssl libgdbm-dev \
    && apt-get install -y build-essential libsqlite3-dev sqlite3 \
    && apt-get install -y libgdbm-compat-dev liblzma-dev libreadline-dev \
    && apt-get install -y libncursesw5-dev libffi-dev uuid-dev

RUN apt-get update && apt-get install -y --allow-downgrades --allow-change-held-packages --no-install-recommends \
        cmake \
        g++-4.8 \
        git \
        curl \
        vim \
        nano \
        wget \
        ca-certificates \
        libjpeg-dev \
        libpng-dev \
        librdmacm1 \
        libibverbs1 \
        ibverbs-providers

RUN rm -rf /var/lib/apt/lists/*
# RUN apt-get install -y wget gcc g++ && rm -rf /var/lib/apt/lists/*

# && apt-get install openssl-devel bzip2-devel expat-devel gdbm-devel readline-devel sqlite-deve -y \
RUN mkdir /tmp/openmpi && \
    cd /tmp/openmpi && \
    wget https://www.open-mpi.org/software/ompi/v4.0/downloads/openmpi-4.0.0.tar.gz && \
    tar zxf openmpi-4.0.0.tar.gz && \
    cd openmpi-4.0.0 && \
    ./configure --enable-orterun-prefix-by-default && \
    make -j $(nproc) all && \
    make install && \
    ldconfig && \
    rm -rf /tmp/openmpi

#python3.7.6 pls compile with --with-ssl or you can not use pip3
RUN cd /tmp \
    && wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz \
    && tar -zvxf Python-${PYTHON_VERSION}.tgz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure --enable-optimizations --with-ssl \
    && make install \
    && ln -sf /usr/local/bin/python3 /usr/bin/python \
    && ln -sf /usr/local/bin/pip3 /usr/bin/pip


# #python3
# RUN wget https://www.python.org/ftp/python/3.7.6/Python-3.7.6.tgz
# RUN tar -zxvf Python-3.7.6.tgz
# RUN mv Python-3.7.6 /usr/local/
# RUN cd /usr/local/Python-3.7.6 && \
#     ./configure && \
#     make && \
#     make install &&\
#     mv /usr/bin/python /usr/bin/python.2 && \
#     ln -sf /usr/local/bin/python3 /usr/bin/python
 
#python3-pip
RUN pip install --upgrade pip
 
#numpy setup
RUN pip install --no-cache-dir sklearn scipy pandas numpy

RUN if [[ "${TFCPU}" == "1" ]]; then \
        pip install --no-cache-dir tensorflow-cpu==${TENSORFLOW_VERSION} ;\
    else \
        pip install --no-cache-dir tensorflow-gpu==${TENSORFLOW_VERSION} ;\
    fi

#horovod setup
RUN HOROVOD_WITH_TENSORFLOW=1 \
    pip install --no-cache-dir horovod[tensorflow,keras]

# Install OpenSSH for MPI to communicate between containers
RUN apt update && \
    apt-get install -y --no-install-recommends openssh-client openssh-server && \
    mkdir -p /var/run/sshd
 
# Allow OpenSSH to talk to containers without asking for confirmation
RUN cat /etc/ssh/ssh_config | grep -v StrictHostKeyChecking > /etc/ssh/ssh_config.new && \
    echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config.new && \
    mv /etc/ssh/ssh_config.new /etc/ssh/ssh_config

# Download examples
RUN apt-get install -y --no-install-recommends subversion && \
    svn checkout https://github.com/horovod/horovod/trunk/examples && \
    rm -rf /examples/.svn

WORKDIR "/examples"