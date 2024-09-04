## Automated K8S cluster deployment

### Purpose

Deploy a K8S cluster on baremetal servers with Cilium L2 CNI, Rook Ceph CSI and KubeVirt on a Virtualized KVM env.

## How to run

Prepare the hardware environment as instructed below and then run:

```
bash install-k8s-all.sh
```

Note: ArgoCD needs SSH key based authentication to the repository with WRITE rights.
It is required to fork this repository and update the repository paths accordingly.

```bash
OLD_BRANCH="insert-here"
CURRENT_BRANCH=$(git branch --show-current
sed -i "s/${OLD_BRANCH}/${CURRENT_BRANCH}/g" applications/workload/templates/*
sed -i "s/${OLD_BRANCH}/${CURRENT_BRANCH}/g" applications/management/templates/*

OLD_REPO="git@github.com:cloudbase\/BMK.git"
CURRENT_REPO="git@github.com:ader1990\/BMK.git"
sed -i "s/${OLD_REPO}/${CURRENT_REPO}/g" applications/workload/templates/*
sed -i "s/${OLD_REPO}/${CURRENT_REPO}/g" applications/management/templates/*
```

TBD: add more documentation on how to add automate the required binaries like k3d/kubectl/clusterctl on the management box.

#### Minimum requirements for virtualized PoC all in one (just basic K8S deployment, no Cilium or Ceph/Rook)

Baremetal or virtual machine host:

  * CPU, 4 cores with enabled virtualization
  * 32 GB RAM
  * 200 GB SSD storage
  * NIC with Internet access

Software:

  * Ubuntu 22.04
  * https://github.com/cloudbase/bmk
  * Run prepare-k8s.sh on the host


`prepare-k8s.sh`:

  * creates a libvirt network tink_network of type "route" using virtual bridge "virbr3": 192.168.56.1/24
  * adds iptables for NAT

  * creates two Libvirt QEMU-KVM VMs:

    * one for the management K8S cluster -> the K8S cluster that manages the lifecycle of the workload cluster
    * one for the workload K8S cluster --> the end goal
    * an extra two VMs for scaling the K8S cluster

  * starts the two VMs

#### Management K8S cluster:

  * one NIC connected to tink_network with static IP: 192.168.56.2, gateway 192.168.56.1 set in netplan
  * created using k3d, has host pid | network control, no loadbalancer, basically as close to the host as possible
  * uses kube-vip for external IPs
  * ArgoCD installed and exposed at: 192.168.56.133:80, HTTP endpoint.
  * Tinkerbell stack installed and exposed at: 192.168.56.130:50061 and 8080, HTTP endpoint and DHCP listening on the vNIC connected to virbr3

#### Workload K8S cluster:

  * minimal cluster, one control plane that can be untainted to be worker node too
  * will be installed using Tinkerbell services (DHCP, PXE of Hook linuxkit OS, Tinkerbell actions that dd the CAPI image, reboot, execute cloud-init metadata + userdata hosted by Tinkerbell, metadata and userdata created by Cluster API)

### Workflow:


  * host: manual: install Ubuntu 22.04 server core, clone repo
  * host: manual: execute prepare-k8s.sh:

    * host: automated: create libvirt network and set iptables rules
    * host: automated: create and start two libvirt domains, one for Management K8S and one for Workload K8S

  * management: manual: configure networking, clone repo (can be automated if an appliance is used)
  * management: manual: configure install-k8s-all.sh according to your extra requirements, if needed
  * management: manual: execute install-k8s-all.sh:

    * management: automated: install Docker
    * management: automated: download all required binaries: k3d, kubectl, helm, clusterctl, argocd
    * management: automated: install ArgoCD
    * management: automated: install Tinkerbell Stack as ArgoCD application
    * management: automated: install CAPI + CAPT services using clusterctl
    * management: automated: deploy Workload Cluster as ArgoCD application
