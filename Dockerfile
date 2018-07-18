ARG PROJECT
ARG DISTRO=centos
ARG TAG=master
ARG FROM=loci/kolla-${PROJECT}-${DISTRO}:${TAG}

FROM ${FROM}

ARG PROJECT
ARG SERVICE
ARG USER=${PROJECT}
ARG KOLLA_VERSION=master

LABEL kolla_version ${KOLLA_VERSION}

COPY install.sh /opt/kolla-loci/

RUN /opt/kolla-loci/install.sh

USER ${USER}
CMD ["kolla_start"]
