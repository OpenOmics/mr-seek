# Base image for mr-seek,
# uses Ubuntu Jammy (LTS)
FROM ubuntu:22.04
LABEL maintainer=kuhnsa@nih.gov

############# OVERVIEW #############
#  • python/3.10 (apt-get python3)
#    - argparse  (standard libary >= 3.5)
#    - gzip      (standard libary)
#    - math      (standard libary)
#    - os        (standard libary)
#  • R/4.2.2
#    - dplyr_1.0.10       (CRAN)
#    - data.table_1.14.6  (CRAN)
#    - optparse_1.7.3     (CRAN)
#    - remotes_2.4.2      (CRAN)
#    - TwoSampleMR_0.5.6  (Github: MRCIEU/TwoSampleMR)
#        @requires: git

############### INIT ################
# Create Container filesystem specific 
# working directory and opt directories
# to avoid collisions with host filesyetem 
RUN mkdir -p /opt2 && mkdir -p /data2
WORKDIR /opt2 
# Set time zone to US east coast 
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

############### SETUP ################
# This section installs system packages 
# required for your project. If you need 
# extra system packages add them here.
RUN apt-get update \
    && apt-get -y upgrade \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        apt-transport-https \
        autotools-dev \
        automake \
        autoconf \
        bcftools \
        build-essential \
        bzip2 \
        ca-certificates \
        cmake \
        curl \
        dirmngr \
        gfortran \
        git \
        gnupg \
        gzip \
        libcairo2-dev \
        libfontconfig1-dev \
        libharfbuzz-dev \
        libfribidi-dev  \
        libgmp-dev \
        libtool \
        libz-dev \
        locales \
        pandoc \
        python3 \
        python3-pip \
        software-properties-common \
        unzip \
        wget \
    && apt-get clean && apt-get purge \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set the locale
RUN localedef -i en_US -f UTF-8 en_US.UTF-8

############### INSTALL ################
# Make python3 the default interpreter
# and install python packages
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN pip3 install --upgrade pip \
    && pip3 install argparse

# Install R (4.2.2)
# For more information, check out: 
# https://cran.r-project.org/bin/linux/ubuntu/
RUN apt-get update -qq \
    # Add the signing key r-project repos
    && wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc \
        | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc \
    && add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/" \
    && apt-get -y install r-base r-base-core r-recommended r-base-dev \
    && apt-get -y install \
        libcurl4-openssl-dev libssl-dev libboost-dev libxml2-dev \
        libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev \
    && apt-get clean && apt-get purge \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# Install required R packages
# CRAN packages
RUN Rscript -e 'install.packages(c("data.table", "dplyr", "optparse", "remotes", "devtools"), repos="http://cran.r-project.org")'
# Github packages
RUN Rscript -e 'devtools::install_github("MRCIEU/TwoSampleMR")'

################ POST #################
# Add Dockerfile and export env variables
ADD Dockerfile /opt2/Dockerfile
RUN chmod -R a+rX /opt2 
ENV PATH="/opt2:$PATH"
WORKDIR /data2
