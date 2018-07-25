ARG PROJECT
ARG KOLLA_BASE_DISTRO=centos
ARG TAG=master
ARG FROM=loci/kolla-${PROJECT}-${KOLLA_BASE_DISTRO}:${TAG}

FROM ${FROM}

ARG PROJECT
ARG SERVICE
ARG USER=${PROJECT}
ARG KOLLA_VERSION=master
ARG KOLLA_BASE_DISTRO=centos

ENV KOLLA_BASE_DISTRO=${KOLLA_BASE_DISTRO}

LABEL kolla_version ${KOLLA_VERSION}

COPY install.sh /opt/kolla-loci/

RUN /opt/kolla-loci/install.sh

USER ${USER}

CMD ["kolla_start"]
