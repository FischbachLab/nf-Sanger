## Base Image
FROM bioconductor/bioconductor_docker:RELEASE_3_12
#FROM alpine:3.14
#FROM geargenomics/tracy:latest
#FROM continuumio/miniconda3:latest
LABEL authors="Xiandong Meng" \
      description="Sanger Assembly and Annotation Pipeline" \
      software.name="Sanger" \
      software.description="" \
      software.website="" \
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
RUN conda install  -c conda-forge -y  awscli  \
  &&  conda install r-isolater=1.0.1-0 -c bdaisley -c conda-forge -c bioconda -y \
  && conda clean -afy

#RUN mkdir -p /work
#WORKDIR /work
#

