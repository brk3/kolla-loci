#!/bin/bash

set -ex

case ${distro} in
    debian|ubuntu)
        # TODO
        ;;
    centos)
        yum -y autoremove git
        yum clean all
        rm -rf /var/cache/yum
        ;;
    *)
        echo "Unknown distro: ${distro}"
        exit 1
        ;;
esac
