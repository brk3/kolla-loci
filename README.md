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
glance_registry_image_full: "{{ loci_registry }}/kolla-loci/glance-registry-{{ kolla_base_distro }}:master"
glance_api_image_full: "{{ loci_registry }}/kolla-loci/glance-api-{{ kolla_base_distro }}:master"

keystone_image_full: "{{ loci_registry }}/kolla-loci/keystone-{{ kolla_base_distro }}:master"
keystone_fernet_image_full: "{{ loci_registry }}/kolla-loci/keystone-fernet-{{ kolla_base_distro }}:master"
keystone_ssh_image_full: "{{ loci_registry }}/kolla-loci/keystone-ssh-{{ kolla_base_distro }}:master"

neutron_dhcp_agent_image_full: "{{ loci_registry }}/kolla-loci/neutron-dhcp-agent-{{ kolla_base_distro }}:master"
neutron_l3_agent_image_full: "{{ loci_registry }}/kolla-loci/neutron-l3-agent-{{ kolla_base_distro }}:master"
neutron_metadata_agent_image_full: "{{ loci_registry }}/kolla-loci/neutron-metadata-agent-{{ kolla_base_distro }}:master"
neutron_openvswitch_agent_image_full: "{{ loci_registry }}/kolla-loci/neutron-openvswitch-agent-{{ kolla_base_distro }}:master"
neutron_server_image_full: "{{ loci_registry }}/kolla-loci/neutron-server-{{ kolla_base_distro }}:master"

nova_libvirt_image_full: "{{ loci_registry }}/kolla-loci/nova-libvirt-{{ kolla_base_distro }}:master"
nova_ssh_image_full: "{{ loci_registry }}/kolla-loci/nova-ssh-{{ kolla_base_distro }}:master"
nova_conductor_image_full: "{{ loci_registry }}/kolla-loci/nova-conductor-{{ kolla_base_distro }}:master"
nova_consoleauth_image_full: "{{ loci_registry }}/kolla-loci/nova-consoleauth-{{ kolla_base_distro }}:master"
nova_novncproxy_image_full: "{{ loci_registry }}/kolla-loci/nova-novncproxy-{{ kolla_base_distro }}:master"
nova_spicehtml5proxy_image_full: "{{ loci_registry }}/kolla-loci/nova-spicehtml5proxy-{{ kolla_base_distro }}:master"
nova_scheduler_image_full: "{{ loci_registry }}/kolla-loci/nova-scheduler-{{ kolla_base_distro }}:master"
nova_compute_image_full: "{{ loci_registry }}/kolla-loci/nova-compute-{{ kolla_base_distro }}:master"
nova_api_image_full: "{{ loci_registry }}/kolla-loci/nova-api-{{ kolla_base_distro }}:master"
nova_serialproxy_image_full: "{{ loci_registry }}/kolla-loci/nova-serialproxy-{{ kolla_base_distro }}:master"
placement_api_image_full: "{{ loci_registry }}/kolla-loci/nova-placement-api-{{ kolla_base_distro }}:master"
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
