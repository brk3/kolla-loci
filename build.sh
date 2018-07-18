#!/bin/bash

set -ex

export PUSH="true"
export REGISTRY="operator-upstream:5000"
export TAG="master"
export DISTRO="centos"

PROJECTS=(keystone glance nova neutron rabbitmq mariadb)
TMPDIR=$(mktemp -d)

build() {
    local project=$1
    local service=$2

    case "${service}" in
        keystone|nova-libvirt|nova-ssh|nova-placement-api)
            user=root
            ;;
        mariadb)
            user=mysql
            ;;
        *)
            user=${project}
            ;;
    esac

    docker build \
      --build-arg PROJECT=${project} \
      --build-arg SERVICE=${service} \
      --build-arg USER=${user} \
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

git clone --depth=1 https://git.openstack.org/openstack/kolla ${TMPDIR}/kolla

for project in ${PROJECTS[@]}; do
    services=$(find ${TMPDIR}/kolla/docker/${project} -type d -exec basename {} \; | sort --unique \
        | grep -v -- -base)
    echo ${services} | xargs --max-procs=0 --delimiter=' ' --max-args=1 --verbose -I {} \
        bash -c "build ${project} \$@" _ {}
done

rm -rf ${TMPDIR}/kolla
