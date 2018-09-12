# kolla-loci
kolla-loci is a project to build kolla-ansible compatible images using Loci.

This project is in beta state and should not be used by anyone.

# Building
``` bash
export REGISTRY=my-registry:5000
./build.sh
```

This will build all supported images by default. Specific ones can also be passed using arguments:

``` bash
./build.sh keystone
```

Centos images are produced by default. Ubuntu can be built by setting the following environment
variable:
``` bash
export KOLLA_BASE_DISTRO=ubuntu
```

# Using in kolla-ansible
Instruct kolla-ansible to use the new images via globals.yml. e.g. To use kolla-loci keystone images
instead of the Kolla's:
``` yaml
keystone_image_full: "my-registry:5000/kolla-loci/keystone-centos:master"
keystone_fernet_image_full: "my-registry:5000/kolla-loci/keystone-fernet-centos:master"
keystone_ssh_image_full: "my-registry:5000/kolla-loci/keystone-ssh-centos:master"
```

# Project Status
The following images should currently work (no CI/CD as of yet)
* keystone
* glance
* nova
* neutron
