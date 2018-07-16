#!/bin/bash

set -ex

project=$1
service=$2

run_as_root=(keystone nova-libvirt nova-ssh nova-placement-api)
user=${project}

for i in "${run_as_root[@]}"; do
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
  --tag operator-upstream:5000/kolla-loci-${service}:centos .

docker push operator-upstream:5000/kolla-loci-${service}:centos
