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
Instruct kolla-ansible to use the new images via globals.yml:
``` yaml
glance_registry_image_full: "{{ loci_registry }}/kolla-loci/glance-registry-centos:master"
glance_api_image_full: "{{ loci_registry }}/kolla-loci/glance-api-centos:master"

keystone_image_full: "{{ loci_registry }}/kolla-loci/keystone-centos:master"
keystone_fernet_image_full: "{{ loci_registry }}/kolla-loci/keystone-fernet-centos:master"
keystone_ssh_image_full: "{{ loci_registry }}/kolla-loci/keystone-ssh-centos:master"

neutron_dhcp_agent_image_full: "{{ loci_registry }}/kolla-loci/neutron-dhcp-agent-centos:master"
neutron_l3_agent_image_full: "{{ loci_registry }}/kolla-loci/neutron-l3-agent-centos:master"
neutron_metadata_agent_image_full: "{{ loci_registry }}/kolla-loci/neutron-metadata-agent-centos:master"
neutron_openvswitch_agent_image_full: "{{ loci_registry }}/kolla-loci/neutron-openvswitch-agent-centos:master"
neutron_server_image_full: "{{ loci_registry }}/kolla-loci/neutron-server-centos:master"

nova_ssh_image_full: "{{ loci_registry }}/kolla-loci/nova-ssh-centos:master"
nova_conductor_image_full: "{{ loci_registry }}/kolla-loci/nova-conductor-centos:master"
nova_consoleauth_image_full: "{{ loci_registry }}/kolla-loci/nova-consoleauth-centos:master"
nova_novncproxy_image_full: "{{ loci_registry }}/kolla-loci/nova-novncproxy-centos:master"
nova_spicehtml5proxy_image_full: "{{ loci_registry }}/kolla-loci/nova-spicehtml5proxy-centos:master"
nova_scheduler_image_full: "{{ loci_registry }}/kolla-loci/nova-scheduler-centos:master"
nova_compute_image_full: "{{ loci_registry }}/kolla-loci/nova-compute-centos:master"
nova_api_image_full: "{{ loci_registry }}/kolla-loci/nova-api-centos:master"
nova_serialproxy_image_full: "{{ loci_registry }}/kolla-loci/nova-serialproxy-centos:master"
placement_api_image_full: "{{ loci_registry }}/kolla-loci/nova-placement-api-centos:master"
```

# Project Status
The following images should currently work (no CI/CD as of yet)
* keystone
* glance
* nova
* neutron

# Known Issues
* For some reason nova\_scheduler will exit on first deploy, and requires to be manually started via
  'docker restart nova\_scheduler'
