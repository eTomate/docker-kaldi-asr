FROM resin/armv7hf-debian

ARG MAKE_JOBS=4

RUN apt-get update && apt-get install --no-install-recommends -y  \
    autoconf \
    automake \
    bzip2 \
    g++ \
    git \
    libatlas3-base \
    libtool-bin \
    make \
    patch \
    python2.7 \
    python3 \
    python-pip \
    subversion \
    wget \
    zlib1g-dev \
    unzip \
    sox \
    gfortran && \
    apt-get clean && \
    apt-get autoclean && \
    apt-get autoremove -y

RUN mkdir -p /opt/kaldi && \
    git clone https://github.com/kaldi-asr/kaldi.git /opt/kaldi
    
WORKDIR /opt/kaldi/tools    
RUN make -j${MAKE_JOBS} && \
    ./install_portaudio.sh

#WORKDIR /opt/kaldi/tools/extras
#RUN ./install_openblas.sh

WORKDIR /opt/kaldi/src
RUN ./configure --shared && \
    sed -i '/-g # -O0 -DKALDI_PARANOID/c\-O3 -DNDEBUG' kaldi.mk

RUN make -j${MAKE_JOBS} depend && \
    make -j${MAKE_JOBS} checkversion && \
    make -j${MAKE_JOBS} kaldi.mk && \
    make -j${MAKE_JOBS} mklibdir && \
    make -j${MAKE_JOBS} \
	base \
	decoder \
	fstext \
	nnet3 \
	online2 \
	util
	
WORKDIR /opt/kaldi
RUN git log -n1 > current-git-commit.txt && \
    rm -rf /opt/kaldi/.git && \
    rm -rf /opt/kaldi/egs/ /opt/kaldi/windows/ /opt/kaldi/misc/ && \
    find /opt/kaldi/src/ \
	 -type f \
	 -not -name '*.h' \
	 -not -name '*.so' \
	 -delete && \
    find /opt/kaldi/tools/ \
	 -type f \
	 -not -name '*.h' \
	 -not -name '*.so' \
	 -not -name '*.so*' \
	 -delete
