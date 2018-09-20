#!/bin/bash

set -ex

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
    usermod -a -G kolla ${USER}
}

function keystone {
    if [[ "${SERVICE}" == "keystone" ]]; then
        cp ${kolla_scripts}/keystone/keystone/keystone_bootstrap.sh \
            /usr/local/bin/kolla_keystone_bootstrap
        chmod 0755 /usr/local/bin/kolla_keystone_bootstrap
    fi
    if [[ "${SERVICE}" == "keystone-ssh" ]]; then
        mkdir -p /var/run/sshd
        chmod 0755 /var/run/sshd
        chsh --shell /bin/bash keystone
        if [[ "${KOLLA_BASE_DISTRO}" == "centos" ]]; then
            # NOTE(pbourke): loci autocleans git which in turn incorrectly removes these packages
            yum -y install rsync
            rm -rf /var/cache/yum
        fi
    fi
    if [[ "${SERVICE}" == "keystone-fernet" ]]; then
        cp ${kolla_scripts}/keystone/keystone-fernet/fetch_fernet_tokens.py /usr/bin/
        cp ${kolla_scripts}/keystone/keystone-fernet/keystone_bootstrap.sh \
            /usr/local/bin/kolla_keystone_bootstrap
        chmod 0755 /usr/local/bin/kolla_keystone_bootstrap /usr/bin/fetch_fernet_tokens.py
        if [[ "${KOLLA_BASE_DISTRO}" == "centos" ]]; then
            # NOTE(pbourke): loci autocleans git which in turn incorrectly removes these packages
            yum -y install rsync openssh-clients
            rm -rf /var/cache/yum
        fi
    fi
}

function nova {
    sed -i 's|^exec_dirs.*|exec_dirs=/var/lib/kolla/venv/bin,/sbin,/usr/sbin,/bin,/usr/bin,/usr/local/bin,/usr/local/sbin|g' /etc/nova/rootwrap.conf
    if [[ "${SERVICE}" == "nova-placement-api" ]]; then
        if [[ "${KOLLA_BASE_DISTRO}" == "centos" ]]; then
            sed -i -r 's,^(Listen 80),#\1,' /etc/httpd/conf/httpd.conf
            sed -i -r 's,^(Listen 443),#\1,' /etc/httpd/conf.d/ssl.conf
        elif [[ "${KOLLA_BASE_DISTRO}" == "ubuntu" ]]; then
            truncate -s 0 /etc/apache2/ports.conf
        fi
    fi
    if [[ "${SERVICE}" == "nova-libvirt" ]]; then
        if [[ "${KOLLA_BASE_DISTRO}" == "ubuntu" ]]; then
            groupadd --force --gid 42427 qemu
            useradd -M --shell /usr/sbin/nologin --uid 42427 --gid 42427 qemu
        fi
        usermod --append --groups qemu nova
    fi
    if [[ "${SERVICE}" == "nova-ssh" ]]; then
        mkdir -p /var/run/sshd
        chmod 0755 /var/run/sshd
    fi
}

function neutron {
    if [[ "${SERVICE}" == "neutron-server" ]]; then
        mkdir /usr/share/neutron
        cp /etc/neutron/api-paste.ini /usr/share/neutron
    fi
    if [[ "${SERVICE}" == "neutron-l3-agent" || "neutron-dhcp-agent" ]]; then
        sed -i 's|^exec_dirs.*|exec_dirs=/var/lib/kolla/venv/bin,/sbin,/usr/sbin,/bin,/usr/bin,/usr/local/bin,/usr/local/sbin|g' /etc/neutron/rootwrap.conf
    fi
}

function rabbitmq {
    rm -rf /var/lib/rabbitmq/*
    ln -s /usr/lib/rabbitmq/lib/rabbitmq_server-3.6.* /usr/lib/rabbitmq/lib/rabbitmq_server-3.6
    curl -o \
        /usr/lib/rabbitmq/lib/rabbitmq_server-3.6/plugins/rabbitmq_clusterer-3.6.x-667f92b0.ez \
        http://www.rabbitmq.com/community-plugins/v3.6.x/rabbitmq_clusterer-3.6.x-667f92b0.ez
    /usr/lib/rabbitmq/bin/rabbitmq-plugins enable --offline \
        rabbitmq_management rabbitmq_clusterer

    cp ${kolla_scripts}/rabbitmq/rabbitmq_get_gospel_node.py \
        /usr/local/bin/rabbitmq_get_gospel_node
}

function mariadb {
    cp ${kolla_scripts}/mariadb/security_reset.expect /usr/local/bin/kolla_security_reset
    chmod 755 /usr/local/bin/kolla_security_reset
    rm -rf /var/lib/mysql/*
    if [[ "${KOLLA_BASE_DISTRO}" == "ubuntu" ]]; then
        mkdir -p /var/run/mysqld
        chown mysql /var/run/mysqld
        chmod 755 /var/run/mysqld
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

case "${PROJECT}" in
    keystone)
        keystone
        ;;
    nova)
        nova
        ;;
    neutron)
        neutron
        ;;
    rabbitmq)
        rabbitmq
        ;;
    mariadb)
        mariadb
        ;;
esac
