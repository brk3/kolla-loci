#!/bin/bash

set -ex

# e.g. build.sh nova nova-api
PROJECT=$1
SERVICE=$2

RUN_AS_ROOT=(keystone nova-libvirt nova-ssh nova-placement-api)
USER=${PROJECT}
TAG=master
DISTRO=centos

for i in "${RUN_AS_ROOT[@]}"; do
    if [[ "${i}" == "${PROJECT}" || "${i}" == "${SERVICE}" ]]; then
        USER="root"
        break
    fi
done

docker build \
  --build-arg PROJECT=${PROJECT} \
  --build-arg SERVICE=${SERVICE} \
  --build-arg USER=${USER} \
  --build-arg http_proxy=$http_proxy \
  --build-arg https_proxy=$https_proxy \
  --build-arg no_proxy=$no_proxy \
  --tag kolla-loci/${SERVICE}-centos:${TAG} .

# TODO(pbourke): add proper arg parsing for this behaviour
docker tag kolla-loci/${SERVICE}-centos:${TAG} \
    operator-upstream:5000/kolla-loci/${SERVICE}-centos:${TAG}
docker push operator-upstream:5000/kolla-loci/${SERVICE}-centos:${TAG}
