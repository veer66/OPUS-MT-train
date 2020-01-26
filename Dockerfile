FROM nvidia/cuda
ENV LANG=C.UTF-8
RUN apt update && apt upgrade -y
RUN apt install -y nvidia-utils-440 ruby wget