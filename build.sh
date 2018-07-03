#!/bin/bash

set -ex

project=$1
service=$2

must_be_root=(keystone)
user=${project}

for i in "${must_be_root[@]}"; do
    if [[ "${i}" == "${project}" ]]; then
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
