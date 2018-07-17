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

    if [[ "$(ls ${kolla_scripts}/${PROJECT}/${PROJECT}-base/*sudo* 2>/dev/null)" != "" ]]; then
        cp ${kolla_scripts}/${PROJECT}/${PROJECT}-base/*sudo* /etc/sudoers.d
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
    else
        touch /usr/local/bin/kolla_${PROJECT}_extend_start
    fi

    chmod 0755 /usr/local/bin/*
}

function copy_default_configs {
    if [[ -d /var/lib/openstack/etc/${PROJECT}/ ]]; then
        cp -r /var/lib/openstack/etc/${PROJECT}/* /etc/${PROJECT}
    fi
}

function setup_user {
    groupadd --force --gid 42400 kolla
    usermod -a -G kolla ${PROJECT}
}

function keystone_workarounds {
    if [[ "${SERVICE}" == "keystone" ]]; then
        yum -y install httpd mod_auth_mellon mod_auth_openidc mod_ssl mod_wsgi python-ldappool
        rm -rf /var/cache/yum
        cp ${kolla_scripts}/keystone/keystone/keystone_bootstrap.sh \
            /usr/local/bin/kolla_keystone_bootstrap
        chmod 0755 /usr/local/bin/kolla_keystone_bootstrap
    fi
    if [[ "${SERVICE}" == "keystone-ssh" ]]; then
        yum -y install openssh openssh-server rsync
        rm -rf /var/cache/yum
        chsh --shell /bin/bash keystone
    fi
    if [[ "${SERVICE}" == "keystone-fernet" ]]; then
        yum -y install rsync openssh-clients
        rm -rf /var/cache/yum
        cp ${kolla_scripts}/keystone/keystone-fernet/fetch_fernet_tokens.py /usr/bin/
        cp ${kolla_scripts}/keystone/keystone-fernet/keystone_bootstrap.sh \
            /usr/local/bin/kolla_keystone_bootstrap
        chmod 0755 /usr/local/bin/kolla_keystone_bootstrap /usr/bin/fetch_fernet_tokens.py
    fi

}

function nova_workarounds {
    sed -i 's|^exec_dirs.*|exec_dirs=/var/lib/kolla/venv/bin,/sbin,/usr/sbin,/bin,/usr/bin,/usr/local/bin,/usr/local/sbin|g' /etc/nova/rootwrap.conf
    if [[ "${SERVICE}" == "nova-ssh" ]]; then
        yum -y install openssh openssh-server
        rm -rf /var/cache/yum
    fi
    if [[ "${SERVICE}" == "nova-placement-api" ]]; then
        yum -y install httpd mod_ssl mod_wsgi
        rm -rf /var/cache/yum

        sed -i -r 's,^(Listen 80),#\1,' /etc/httpd/conf/httpd.conf
        sed -i -r 's,^(Listen 443),#\1,' /etc/httpd/conf.d/ssl.conf
    fi
    if [[ "${SERVICE}" == "nova-compute" ]]; then
        yum -y install http://mirror.centos.org/centos-7/7/extras/x86_64/Packages/centos-release-qemu-ev-1.0-2.el7.noarch.rpm
        yum -y install libvirt-python qemu-img openvswitch bridge-utils
        rm -rf /var/cache/yum

        # NOTE(pbourke): needs to be same as kolla's nova-libvirt
        usermod -u 42436 nova
        groupmod -g 42436 nova
    fi
}

function neutron_workarounds {
    if [[ "${SERVICE}" == "neutron-server" ]]; then
        mkdir /usr/share/neutron
        cp /etc/neutron/api-paste.ini /usr/share/neutron
    fi
    if [[ "${SERVICE}" == "neutron-openvswitch-agent" ]]; then
        yum -y install openvswitch
        rm -rf /var/cache/yum
    fi
    if [[ "${SERVICE}" == "neutron-l3-agent" || "neutron-dhcp-agent" ]]; then
        sed -i 's|^exec_dirs.*|exec_dirs=/var/lib/kolla/venv/bin,/sbin,/usr/sbin,/bin,/usr/bin,/usr/local/bin,/usr/local/sbin|g' /etc/neutron/rootwrap.conf
        yum -y install iproute
        rm -rf /var/cache/yum
    fi
}

pip install --no-deps --no-cache-dir kolla

mkdir /var/lib/kolla
ln -s /var/lib/openstack /var/lib/kolla/venv

copy_base
copy_sudoers
copy_start
copy_default_configs
setup_user

# TODO(pbourke): revisit workarounds once we have kolla profile in loci
if [[ "${PROJECT}" == "keystone" ]]; then
    keystone_workarounds
fi

if [[ "${PROJECT}" == "nova" ]]; then
    nova_workarounds
fi

if [[ "${PROJECT}" == "neutron" ]]; then
    neutron_workarounds
fi
