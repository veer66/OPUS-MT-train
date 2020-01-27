FROM nvidia/cuda:9.0-devel
ENV LANG=C.UTF-8
RUN apt update && \
    apt upgrade -y && \
    apt install -y ruby wget git cmake g++ libboost-all-dev \
                   doxygen graphviz libblas-dev libopenblas-dev \
		   libz-dev libssl-dev zlib1g-dev libbz2-dev liblzma-dev \
		   libprotobuf9v5 protobuf-compiler libprotobuf-dev \
		   python3-dev python3-numpy python3-setuptools
RUN wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    rm GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB && \
    wget https://apt.repos.intel.com/setup/intelproducts.list -O /etc/apt/sources.list.d/intelproducts.list &&  \
    apt update && \
    apt install -y intel-mkl-64bit-2020.0-088
RUN cd / && \
    git clone https://github.com/aboSamoor/pycld2.git && \
    cd pycld2 && \
    git checkout e3ac86e && \
    python3 setup.py build && \
    python3 setup.py install
RUN cd / && \
    git clone https://github.com/saffsd/langid.py.git && \
    cd langid.py && \
    git checkout 4153583 && \
    python3 setup.py build && \
    python3 setup.py install    
RUN cd / && \
    git clone https://github.com/Helsinki-NLP/OpusTools.git && \
    cd OpusTools && \
    git checkout d33b9f3 && \
    cd opustools_pkg && \
    python3 setup.py build && \
    python3 setup.py install    
RUN cd / && \
    git clone https://github.com/marian-nmt/marian-dev && \
    cd marian-dev && \
    git checkout 1.8.0 && \
    mkdir build && \
    cd build && \
    cmake .. \
     	   -DUSE_SENTENCEPIECE=on \
	   -DCOMPILE_CPU=on \
	   -DPROTOBUF_LIBRARY=/usr/lib/x86_64-linux-gnu/libprotobuf.so.9 \
	   -DPROTOBUF_INCLUDE_DIR=/usr/include/google/protobuf \
	   -DPROTOBUF_PROTOC_EXECUTABLE=/usr/bin/protoc && \
    make -j `nproc`
RUN cd / && \
    git clone --depth 1 https://github.com/veer66/mosesdecoder.git && \
    cd /mosesdecoder && \
    ./bjam -j8
