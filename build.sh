#!/bin/bash

set -ex

export KOLLA_BASE_DISTRO=${KOLLA_BASE_DISTRO:="centos"}
export REGISTRY=${REGISTRY:="operator-upstream:5000"}
export TAG=${TAG:="master"}

PROJECTS=(keystone glance nova neutron rabbitmq mariadb)
TMPDIR=$(mktemp -d)

build_loci() {
    local project=$1

    #git init ${TMPDIR}/loci
    #pushd ${TMPDIR}/loci
    #git pull https://git.openstack.org/openstack/loci refs/changes/55/583255/7
    pushd /root/loci

    case "${project}" in
        rabbitmq|mariadb)
            local loci_project="infra"
            ;;
        *)
            local loci_project="${project}"
    esac

    case "${KOLLA_BASE_DISTRO}" in
        centos)
            docker build dockerfiles/centos/ \
                --build-arg http_proxy=$http_proxy \
                --build-arg https_proxy=$https_proxy \
                --build-arg no_proxy=$no_proxy \
                --tag loci/centos:master
            from=loci/centos:master
            ;;
        ubuntu)
            docker build dockerfiles/ubuntu/ \
                --build-arg http_proxy=$http_proxy \
                --build-arg https_proxy=$https_proxy \
                --build-arg no_proxy=$no_proxy \
                --tag loci/ubuntu:master
            from=loci/ubuntu:master
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
        --build-arg PROJECT=requirements \
        --build-arg FROM=${from} \
        --tag loci/requirements-${KOLLA_BASE_DISTRO}:${TAG}

    docker tag loci/requirements-${KOLLA_BASE_DISTRO}:${TAG} \
        ${REGISTRY}/loci/requirements-${KOLLA_BASE_DISTRO}:${TAG}
    docker push ${REGISTRY}/loci/requirements-${KOLLA_BASE_DISTRO}:${TAG}

    docker build . \
        --build-arg http_proxy=$http_proxy \
        --build-arg https_proxy=$https_proxy \
        --build-arg no_proxy=$no_proxy \
        --build-arg PROJECT=${loci_project} \
        --build-arg PROFILES="kolla ${project}" \
        --build-arg FROM=${from} \
        --build-arg WHEELS="${REGISTRY}/loci/requirements-${KOLLA_BASE_DISTRO}:${TAG}" \
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

    docker tag kolla-loci/${service}-${KOLLA_BASE_DISTRO}:${TAG} \
        ${REGISTRY}/kolla-loci/${service}-${KOLLA_BASE_DISTRO}:${TAG}
    docker push ${REGISTRY}/kolla-loci/${service}-${KOLLA_BASE_DISTRO}:${TAG}
}

export -f build_loci
export -f build_kolla_loci

if [[ "$@" != "" ]]; then
    PROJECTS=($@)
fi

# Build the loci base images using the kolla profile
echo ${PROJECTS[@]} | xargs --max-procs=0 --delimiter=' ' --max-args=1 --verbose -I {} \
    bash -e -x -c "build_loci \$@" _ {}

# Build the kolla-loci images
git clone --depth=1 https://git.openstack.org/openstack/kolla ${TMPDIR}/kolla
for project in ${PROJECTS[@]}; do
    services=$(find ${TMPDIR}/kolla/docker/${project} -type d -exec basename {} \; | sort --unique \
        | grep -v -- -base)
    echo ${services} | xargs --max-procs=0 --delimiter=' ' --max-args=1 --verbose -I {} \
        bash -e -x -c "build_kolla_loci ${project} \$@" _ {}
done

rm -rf ${TMPDIR}
