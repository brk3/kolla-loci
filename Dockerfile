ARG PROJECT
ARG TAG=master-centos

FROM loci/${PROJECT}:${TAG}

ARG DISTRO
ARG PROJECT
ARG SERVICE
ARG USER=${PROJECT}
ARG KOLLA_VERSION=master

LABEL kolla_version ${KOLLA_VERSION}

COPY scripts /opt/kolla-loci/scripts

RUN /opt/kolla-loci/scripts/install.sh

USER ${USER}
CMD ["kolla_start"]
