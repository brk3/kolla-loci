ARG PROJECT
ARG TAG=master-centos

FROM loci/${PROJECT}:${TAG}

ARG DISTRO
ARG PROJECT
ARG SERVICE

COPY scripts /opt/kolla-loci/scripts

RUN /opt/kolla-loci/scripts/install.sh

USER ${PROJECT}
CMD ["kolla_start"]
