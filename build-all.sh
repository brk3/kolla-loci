#!/bin/bash

set -ex

# Images currently published by loci
#loci=(cinder glance heat horizon ironic keystone neutron nova octavia)

loci=(keystone)

git clone --depth=1 https://git.openstack.org/openstack/kolla

for project in ${loci[@]}; do
    services=$(find kolla/docker/${project} -type d -exec basename {} \;)
    echo ${services} | xargs -P0 -n1 -t $(dirname $0)/build.sh ${project}
done

rm -rf kolla
