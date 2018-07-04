#!/bin/bash

set -x

kolla_scripts="/var/lib/openstack/share/kolla/docker"

function copy_base {
    cp ${kolla_scripts}/base/set_configs.py /usr/local/bin/kolla_set_configs
    cp ${kolla_scripts}/base/start.sh /usr/local/bin/kolla_start
    cp ${kolla_scripts}/base/sudoers /etc/sudoers
    chmod 0755 /usr/local/bin/*
}

function copy_sudoers {
    if [[ "$(ls ${kolla_scripts}/${PROJECT}/*sudo* 2>/dev/null)" != "" ]]; then
        cp ${kolla_scripts}/${PROJECT}/*sudo* /etc/sudoers.d
    fi

    if [[ "$(ls ${kolla_scripts}/${PROJECT}-base/*sudo* 2>/dev/null)" != "" ]]; then
        cp ${kolla_scripts}/${PROJECT}-base/*sudo* /etc/sudoers.d
    fi

    if [[ "$(ls ${kolla_scripts}/${PROJECT}/${SERVICE}/*sudo* 2>/dev/null)" != "" ]]; then
        cp ${kolla_scripts}/${PROJECT}/${SERVICE}/*sudo* /etc/sudoers.d
    fi
}

function copy_start {
    if [[ -f ${kolla_scripts}/${PROJECT}/${PROJECT}-base/extend_start.sh ]]; then
        cp ${kolla_scripts}/${PROJECT}/${PROJECT}-base/extend_start.sh \
            /usr/local/bin/kolla_extend_start
    elif [[ -f ${kolla_scripts}/${PROJECT}/${SERVICE}/extend_start.sh ]]; then
        cp ${kolla_scripts}/${PROJECT}/${SERVICE}/extend_start.sh \
            /usr/local/bin/kolla_extend_start
    fi

    if [[ -f ${kolla_scripts}/${PROJECT}/extend_start.sh ]]; then
        cp ${kolla_scripts}/${PROJECT}/extend_start.sh /usr/local/bin/kolla_extend_start
    fi

    if [[ -f ${kolla_scripts}/${PROJECT}/${SERVICE}/extend_start.sh ]]; then
        cp ${kolla_scripts}/${PROJECT}/${SERVICE}/extend_start.sh \
            /usr/local/bin/kolla_${PROJECT}_extend_start
    fi

    chmod 0755 /usr/local/bin/*
}

function copy_default_configs {
    if [[ -d /var/lib/openstack/etc/${PROJECT}/ ]]; then
        cp -r /var/lib/openstack/etc/${PROJECT}/* /etc/${PROJECT}
    fi
}

# TODO(pbourke): revisit once we have kolla profile in loci
function keystone_workarounds {
    if [[ "${SERVICE}" == "keystone" ]]; then
        yum -y install httpd mod_auth_mellon mod_auth_openidc mod_ssl mod_wsgi python-ldappool
        yum clean all
        cp ${kolla_scripts}/keystone/keystone/keystone_bootstrap.sh \
            /usr/local/bin/kolla_keystone_bootstrap
        chmod 0755 /usr/local/bin/kolla_keystone_bootstrap
    fi
    if [[ "${SERVICE}" == "keystone-ssh" ]]; then
        yum -y install openssh openssh-server rsync
        yum clean all
        chsh --shell /bin/bash keystone
    fi
    if [[ "${SERVICE}" == "keystone-fernet" ]]; then
        yum -y install rsync openssh-clients
        yum clean all
        cp ${kolla_scripts}/keystone/keystone-fernet/fetch_fernet_tokens.py /usr/bin/
        cp ${kolla_scripts}/keystone/keystone-fernet/keystone_bootstrap.sh \
            /usr/local/bin/kolla_keystone_bootstrap
        chmod 0755 /usr/local/bin/kolla_keystone_bootstrap /usr/bin/fetch_fernet_tokens.py
    fi

    mkdir /var/lib/kolla
    ln -s /var/lib/openstack /var/lib/kolla/venv
}

function setup_user {
    groupadd --force --gid 42400 kolla
    usermod -a -G kolla ${PROJECT}
}

pip install --no-deps --no-cache-dir kolla

copy_base
copy_sudoers
copy_start
copy_default_configs
setup_user

if [[ "${PROJECT}" == "keystone" ]]; then
    keystone_workarounds
fi
