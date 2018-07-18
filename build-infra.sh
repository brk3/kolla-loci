#!/bin/bash

set -ex

export PUSH="true"
export REGISTRY="operator-upstream:5000"
export TAG="master"
export DISTRO="centos"

PROJECTS=(rabbitmq)

build() {
    local project=$1
    local service=$2

    docker build \
      --build-arg PROJECT=${project} \
      --build-arg SERVICE=${service} \
      --build-arg USER=${service} \
      --build-arg FROM=loci/${service}:${TAG}-${DISTRO} \
      --build-arg http_proxy=$http_proxy \
      --build-arg https_proxy=$https_proxy \
      --build-arg no_proxy=$no_proxy \
      --tag kolla-loci/${service}-${DISTRO}:${TAG} .

    if [[ "${PUSH}" == "true" ]]; then
        docker tag kolla-loci/${service}-${DISTRO}:${TAG} \
            ${REGISTRY}/kolla-loci/${service}-${DISTRO}:${TAG}
        docker push ${REGISTRY}/kolla-loci/${service}-${DISTRO}:${TAG}
    fi
}

export -f build

if [[ "$@" != "" ]]; then
    PROJECTS=($@)
fi

echo ${PROJECTS} | xargs --max-procs=0 --delimiter=' ' --max-args=1 --verbose -I {} \
    bash -c "build infra \$@" _ {}
