#!/bin/bash

set -ex

export KOLLA_BASE_DISTRO=${KOLLA_BASE_DISTRO:="centos"}
export REGISTRY=${REGISTRY:="myregistry:5000"}
export TAG=${TAG:="master"}
export BUILD_WHEELS=${BUILD_WHEELS:="no"}

PROJECTS=(keystone glance nova neutron mariadb cron)
TMPDIR=$(mktemp -d)
mkdir -p /tmp/kolla-loci-logs

build_loci() {
    local project=$1

    # TODO(pbourke): remove if/when https://review.openstack.org/#/c/583255/ merges
    pushd /root/loci

    case "${project}" in
        rabbitmq|mariadb|cron)
            local loci_project="infra"
            ;;
        *)
            local loci_project="${project}"
    esac

    # Build the top level loci image
    case "${KOLLA_BASE_DISTRO}" in
        centos)
            docker build dockerfiles/centos/ \
                --build-arg http_proxy=$http_proxy \
                --build-arg https_proxy=$https_proxy \
                --build-arg no_proxy=$no_proxy \
                --tag loci/centos:master
            ;;
        ubuntu)
            docker build dockerfiles/ubuntu/ \
                --build-arg http_proxy=$http_proxy \
                --build-arg https_proxy=$https_proxy \
                --build-arg no_proxy=$no_proxy \
                --tag loci/ubuntu:master
            ;;
        *)
            echo "Unknown distro: ${KOLLA_BASE_DISTRO}"
            exit 1
            ;;
    esac

    # Build loci requirements image (wheels)
    wheels="loci/requirements:${TAG}-${KOLLA_BASE_DISTRO}"
    if [[ "${BUILD_WHEELS}" == "yes" ]]; then
        docker build . \
            --build-arg http_proxy=$http_proxy \
            --build-arg https_proxy=$https_proxy \
            --build-arg no_proxy=$no_proxy \
            --build-arg PROJECT=requirements \
            --build-arg FROM=loci/${KOLLA_BASE_DISTRO}:${TAG} \
            --tag loci/requirements-${KOLLA_BASE_DISTRO}:${TAG}

        # TODO(pbourke): registry push should not be necessary but local wheel layers in loci need
        # some improvement
        docker tag loci/requirements-${KOLLA_BASE_DISTRO}:${TAG} \
            ${REGISTRY}/loci/requirements-${KOLLA_BASE_DISTRO}:${TAG}
        docker push ${REGISTRY}/loci/requirements-${KOLLA_BASE_DISTRO}:${TAG}

        wheels="${REGISTRY}/loci/requirements-${KOLLA_BASE_DISTRO}:${TAG}"
    fi

    # Build the main loci image
    docker build . \
        --build-arg http_proxy=$http_proxy \
        --build-arg https_proxy=$https_proxy \
        --build-arg no_proxy=$no_proxy \
        --build-arg PROJECT=${loci_project} \
        --build-arg PROFILES="kolla ${project}" \
        --build-arg FROM=loci/${KOLLA_BASE_DISTRO}:${TAG} \
        --build-arg WHEELS="${wheels}" \
        --tag loci/kolla-${project}-${KOLLA_BASE_DISTRO}:${TAG} \
        | tee /tmp/kolla-loci-logs/kolla-${project}-${KOLLA_BASE_DISTRO}:${TAG}.log

    popd
}

build_kolla_loci() {
    local project=$1
    local service=$2

    case "${service}" in
        keystone*|nova-libvirt|nova-ssh|nova-placement-api|cron)
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
      --tag kolla-loci/${service}-${KOLLA_BASE_DISTRO}:${TAG} . \
      | tee /tmp/kolla-loci-logs/${service}-${KOLLA_BASE_DISTRO}:${TAG}.log

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
