FROM nvidia/cuda:8.0-devel
ENV LANG=C.UTF-8
RUN apt update && apt upgrade -y
RUN apt install -y ruby wget git cmake g++ libboost-all-dev doxygen graphviz libblas-dev libopenblas-dev libz-dev libssl-dev 
RUN wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    rm GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    wget https://apt.repos.intel.com/setup/intelproducts.list -O /etc/apt/sources.list.d/intelproducts.list &&  \
    apt update && \
    apt install -y intel-mkl-64bit-2020.0-088
WORKDIR /
RUN git clone https://github.com/marian-nmt/marian-dev && \
    cd marian-dev && \
    git checkout 1.8.0 && \
    cmake . && \
    make -j `nproc`
