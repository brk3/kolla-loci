#!/bin/bash

set -ex

export PUSH="true"
export REGISTRY="operator-upstream:5000"
export TAG="master"
export KOLLA_BASE_DISTRO="centos"

PROJECTS=(keystone glance nova neutron rabbitmq mariadb)
TMPDIR=$(mktemp -d)

build_loci() {
    local project=$1

    git init ${TMPDIR}/loci
    pushd ${TMPDIR}/loci
    git pull https://git.openstack.org/openstack/loci refs/changes/55/583255/6

    case "${KOLLA_BASE_DISTRO}" in
        centos)
            from=centos:7
            ;;
        ubuntu)
            from=ubuntu:xenial
            ;;
        *)
            echo "Unknown distro: ${KOLLA_BASE_DISTRO}"
            exit 1
            ;;
    esac

    docker build . \
        --build-arg http_proxy=$http_proxy \
        --build-arg https_proxy=$https_proxy \
        --build-arg no_proxy=$no_proxy \
        --build-arg PROJECT=${project} \
        --build-arg PROFILES="kolla ${project}" \
        --build-arg FROM=${from} \
        --build-arg WHEELS="loci/requirements:${TAG}-${KOLLA_BASE_DISTRO}" \
        --tag loci/kolla-${project}-${KOLLA_BASE_DISTRO}:${TAG}

    popd
}

build_kolla_loci() {
    local project=$1
    local service=$2

    case "${service}" in
        keystone*|nova-libvirt|nova-ssh|nova-placement-api)
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
      --build-arg KOLLA_BASE_DISTRO=${KOLLA_BASE_DISTRO} \
      --build-arg http_proxy=$http_proxy \
      --build-arg https_proxy=$https_proxy \
      --build-arg no_proxy=$no_proxy \
      --tag kolla-loci/${service}-${KOLLA_BASE_DISTRO}:${TAG} .

    if [[ "${PUSH}" == "true" ]]; then
        docker tag kolla-loci/${service}-${KOLLA_BASE_DISTRO}:${TAG} \
            ${REGISTRY}/kolla-loci/${service}-${KOLLA_BASE_DISTRO}:${TAG}
        docker push ${REGISTRY}/kolla-loci/${service}-${KOLLA_BASE_DISTRO}:${TAG}
    fi
}

export -f build_loci
export -f build_kolla_loci

if [[ "$@" != "" ]]; then
    PROJECTS=($@)
fi

# Build the loci base images using the kolla profile
echo ${PROJECTS[@]} | xargs --max-procs=0 --delimiter=' ' --max-args=1 --verbose -I {} \
    bash -c "build_loci \$@" _ {}

# Build the kolla-loci images
git clone --depth=1 https://git.openstack.org/openstack/kolla ${TMPDIR}/kolla
for project in ${PROJECTS[@]}; do
    services=$(find ${TMPDIR}/kolla/docker/${project} -type d -exec basename {} \; | sort --unique \
        | grep -v -- -base)
    echo ${services} | xargs --max-procs=0 --delimiter=' ' --max-args=1 --verbose -I {} \
        bash -c "build_kolla_loci ${project} \$@" _ {}
done

rm -rf ${TMPDIR}
