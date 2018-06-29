#!/bin/bash

set -ex

distro=$(awk -F= '/^ID=/ {gsub(/\"/, "", $2); print $2}' /etc/*release)
export distro=${DISTRO:=$distro}

case ${distro} in
    debian|ubuntu)
        # TODO
        ;;
    centos)
        yum -y install git
        pip install --no-cache-dir git+https://github.com/brk3/kolla-scripts
        ;;
    *)
        echo "Unknown distro: ${distro}"
        exit 1
        ;;
esac

$(dirname $0)/config.sh
$(dirname $0)/cleanup.sh
