## Base Image
FROM bioconductor/bioconductor_docker:RELEASE_3_12
#FROM alpine:3.14
#FROM geargenomics/tracy:latest
#FROM continuumio/miniconda3:latest
LABEL authors="Xiandong Meng" \
      description="Sanger Assembly and Annotation Pipeline" \
      software.name="Sanger" \
      software.description="" \
      software.website="https://github.com/FischbachLab/" \
      container.category="tool"

USER root:root

# Install miniconda
ENV CONDA_DIR /opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
     /bin/bash ~/miniconda.sh -b -p /opt/conda

# Put conda in path so we can use conda activate
#ENV PATH=$CONDA_DIR/bin:$PATH

ENV PATH "/opt/conda/bin:$PATH"

# Update conda to latest version.
RUN conda update -n base -c defaults conda

# Add conda channels
RUN conda config --add channels defaults
RUN conda config --add channels bioconda
RUN conda config --add channels conda-forge

#
RUN conda install  -c conda-forge -y  ncurses bc awscli tracy=0.7.2  unzip readline  blast python pandas numpy \
  &&  conda install -c r r-base  \
  &&  conda install -c r r-essentials \
  && conda install -c r r-tidyverse \
  && conda clean -afy

#RUN echo 'will cite' | parallel --citation || true

RUN mkdir -p /work
WORKDIR /work

# Get Repo
COPY . .

RUN chmod -R +rx ./
