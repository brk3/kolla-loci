#!/bin/bash

set -ex

kolla_scripts="/var/lib/openstack/lib/python2.7/site-packages/kolla_scripts"

cp ${kolla_scripts}/base/set_configs.py /usr/local/bin/kolla_set_configs
cp ${kolla_scripts}/base/start.sh /usr/local/bin/kolla_start
cp ${kolla_scripts}/base/sudoers /etc/sudoers

if [[ "$(ls ${kolla_scripts}/${PROJECT}/${SERVICE}/*sudo* 2>/dev/null)" != "" ]]; then
    cp "${kolla_scripts}/${PROJECT}/${SERVICE}/*sudo*" /etc/sudoers.d
fi

cp ${kolla_scripts}/${PROJECT}/${SERVICE}/extend_start.sh /usr/local/bin/kolla_extend_start
cp ${kolla_scripts}/${PROJECT}/${SERVICE}/extend_start.sh /usr/local/bin/kolla_${PROJECT}_extend_start

chmod 0755 /usr/local/bin/*

cp -r /var/lib/openstack/etc/${PROJECT}/* /etc/${PROJECT}

groupadd --force --gid 42400 kolla
usermod -a -G kolla ${PROJECT}
