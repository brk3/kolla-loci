#!/bin/bash

set -ex

export PUSH="true"
export REGISTRY="operator-upstream:5000"
export TAG="master"
export DISTRO="centos"

export PROJECTS=(keystone glance nova neutron)
export RUN_AS_ROOT=(keystone nova-libvirt nova-ssh nova-placement-api)
export TMPDIR=$(mktemp -d)

build() {
    local project=$1
    local service=$2

    local user=${project}

    for i in "${RUN_AS_ROOT[@]}"; do
        if [[ "${i}" == "${project}" || "${i}" == "${service}" ]]; then
            user="root"
            break
        fi
    done

    docker build \
      --build-arg PROJECT=${project} \
      --build-arg SERVICE=${service} \
      --build-arg USER=${user} \
      --build-arg http_proxy=$http_proxy \
      --build-arg https_proxy=$https_proxy \
      --build-arg no_proxy=$no_proxy \
      --tag kolla-loci/${service}-centos:${TAG} .

    if [[ "${PUSH}" == "true" ]]; then
        docker tag kolla-loci/${service}-centos:${TAG} \
            ${REGISTRY}/kolla-loci/${service}-centos:${TAG}
        docker push ${REGISTRY}/kolla-loci/${service}-centos:${TAG}
    fi
}

export -f build

if [[ "$@" != "" ]]; then
    PROJECTS=($@)
fi

git clone --depth=1 https://git.openstack.org/openstack/kolla ${TMPDIR}/kolla

for project in ${PROJECTS[@]}; do
    services=$(find ${TMPDIR}/kolla/docker/${project} -type d -exec basename {} \; | sort --unique \
        | grep -v -- -base)
    echo ${services} | xargs --max-procs=0 --delimiter=' ' --max-args=1 --verbose -I {} \
        bash -c "build ${project} \$@" _ {}
done

rm -rf ${TMPDIR}/kolla
