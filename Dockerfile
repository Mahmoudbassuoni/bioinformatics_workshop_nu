FROM continuumio/miniconda3
MAINTAINER Mahmoud Bassyouni <mbassyouni@nu.edu.eg>
LABEL description="Image for use with the alginemnt and variant calling tuotrial for the 4th Bioinformatics workshop at Nile University"

####################################
#install basic libraries and python#
####################################
WORKDIR /opt
RUN	mkdir -p /var/cache/apt/archives/partial && \ 
	conda update -y -n base -c defaults conda && \
	apt-get update && apt-get install -y autoconf curl uuid-runtime \
	libcairo2-dev libjpeg-dev libgif-dev less htop unzip \
        apt-utils \
        automake\
        make\
        ncurses-dev \
        gcc\
        perl\
        libcurl4-gnutls-dev\
        wget git\
        bzip2 libbz2-dev \
        zlib1g zlib1g-dev \
        liblzma-dev gnuplot \
        ca-certificates gawk \
        libssl-dev \
        libncurses5-dev \
        libz-dev \
        python3-distutils python3-dev python3-pip \
        libjemalloc-dev \
        cmake make g++ \
        libhts-dev \
        libzstd-dev \
        autoconf \
        libatomic-ops-dev \
        pkg-config \
        cargo \
        pigz \
        && apt-get -y clean all \
        && rm -rf /var/cache

#####
#BWA#
#####
RUN conda install -y -c bioconda bwa
##########
#samtools#
##########
RUN conda install -y -c bioconda samtools
########
#htslib#
########
RUN conda install -y -c bioconda htslib
####
#vt#
####
WORKDIR /opt
RUN git clone https://github.com/atks/vt.git && \ 
	cd vt && git submodule update --init --recursive && \
	make 
ENV PATH=/opt/vt:$PATH
###########
#freebayes#
###########
RUN conda install -y -c bioconda freebayes

########
#vcflib#
########
RUN conda install -y -c bioconda vcflib

##########
#sambamba#
##########
RUN conda install -y -c bioconda sambamba

#######
#Seqtk#
#######
RUN conda install -y -c bioconda seqtk

###########
#sra-tools#
###########
ARG VERSION=current
RUN curl https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/${VERSION}/sratoolkit.${VERSION}-centos_linux64-cloud.tar.gz | tar xz -C /
ENV PATH=/usr/local/ncbi/sra-tools/bin:${PATH}
RUN mkdir -p /root/.ncbi && \
    printf '/LIBS/IMAGE_GUID = "%s"\n' `uuidgen` > /root/.ncbi/user-settings.mkfg && \
    printf '/libs/cloud/report_instance_identity = "true"\n' >> /root/.ncbi/user-settings.mkfg

##########
#bcftools#
##########
ENV BCFTOOLS_INSTALL_DIR=/opt/bcftools
ENV BCFTOOLS_VERSION=1.16

WORKDIR /tmp
RUN wget https://github.com/samtools/bcftools/releases/download/$BCFTOOLS_VERSION/bcftools-$BCFTOOLS_VERSION.tar.bz2 && \
  tar --bzip2 -xf bcftools-$BCFTOOLS_VERSION.tar.bz2

WORKDIR /tmp/bcftools-$BCFTOOLS_VERSION
RUN make prefix=$BCFTOOLS_INSTALL_DIR && \
    make prefix=$BCFTOOLS_INSTALL_DIR install

WORKDIR /
RUN     ln -s $BCFTOOLS_INSTALL_DIR/bin/bcftools /usr/bin/bcftools && \
	rm -rf /tmp/bcftools-$BCFTOOLS_VERSION
########
#Mothur#
########
WORKDIR /opt
RUN wget https://github.com/mothur/mothur/releases/download/v1.48.0/Mothur.Ubuntu_20.zip && \
    unzip Mothur.Ubuntu_20.zip 

ENV PATH=/opt/mothur:$PATH
