#!/bin/bash

set -ex

#loci=(keystone glance nova neutron)
loci=(keystone)

git clone --depth=1 https://git.openstack.org/openstack/kolla

for project in ${loci[@]}; do
    services=$(find kolla/docker/${project} -type d -exec basename {} \; | grep -v -- -base)
    echo ${services} | xargs -P0 -n1 -t $(dirname $0)/build.sh ${project}
done

rm -rf kolla
