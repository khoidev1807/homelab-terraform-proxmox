THIS MODULE IS FOR CREATING TALOS-CLUSTER

refs 
- https://registry.terraform.io/providers/bpg/proxmox/latest/docs#api-token-authentication
- https://docs.siderolabs.com/talos/v1.13/platform-specific-installations/virtualized-platforms/proxmox#proxmox
- https://factory.talos.dev/
- https://docs.cilium.io/en/latest/network/servicemesh/gateway-api/gateway-api/

WHAT DOES THIS SOLVE ?
we can programaticly create talos cluster with one controll-plane and n worker nodes with terraform

1. Create a user for terraform in proxmox

docs: https://registry.terraform.io/providers/bpg/proxmox/latest/docs

do this in proxmox server

pveum user add terraform@pve

pveum role add Terraform -privs "Realm.AllocateUser, VM.PowerMgmt, VM.GuestAgent.Unrestricted, Sys.Console, Sys.Audit, Sys.AccessNetwork, VM.Config.Cloudinit, VM.Replicate, Pool.Allocate, SDN.Audit, Realm.Allocate, SDN.Use, Mapping.Modify, VM.Config.Memory, VM.GuestAgent.FileSystemMgmt, VM.Allocate, SDN.Allocate, VM.Console, VM.Clone, VM.Backup, Datastore.AllocateTemplate, VM.Snapshot, VM.Config.Network, Sys.Incoming, Sys.Modify, VM.Snapshot.Rollback, VM.Config.Disk, Datastore.Allocate, VM.Config.CPU, VM.Config.CDROM, Group.Allocate, Datastore.Audit, VM.Migrate, VM.GuestAgent.FileWrite, Mapping.Use, Datastore.AllocateSpace, Sys.Syslog, VM.Config.Options, Pool.Audit, User.Modify, VM.Config.HWType, VM.Audit, Sys.PowerMgmt, VM.GuestAgent.Audit, Mapping.Audit, VM.GuestAgent.FileRead, Permissions.Modify"

pveum aclmod / -user terraform@pve -role Terraform

pveum user token add terraform@pve provider --privsep=0

2. Create a ssh key for terraform user on the server
do this on local development machine

ssh-keygen -t ed25519 -f ./ssh-keys/proxmox_terraform -N ""

ssh-copy-id -i ./ssh-keys/proxmox_terraform.pub root@proxmox.109lcpalhcm.crabdance.com

3. Build talos iso with qemu-agent

docs: https://docs.siderolabs.com/talos/v1.13/platform-specific-installations/virtualized-platforms/proxmox#proxmox

use this link https://factory.talos.dev/

- qemu-agent (for proxmox)
- iscsi-tools (for longhorn)
- util-linux-tools (for longhorn)

4. Set up talos config with qemu-agent image latest version

docs: https://docs.siderolabs.com/talos/v1.13/platform-specific-installations/virtualized-platforms/proxmox#proxmox

talosctl gen config talos-proxmox-cluster https://192.168.11.11:6443 --output-dir ./talos-configs/configs/  --install-image factory.talos.dev/nocloud-installer-secureboot/861a91152157e97c900df9ca48fe4a26f19f19795e081386751bb7994c16800f:v1.13.0 --config-patch @./talos-configs/patches/initital-setup.yaml  --kubernetes-version 1.36.0

5. Set up control plane node 

docs: https://docs.siderolabs.com/talos/v1.13/platform-specific-installations/virtualized-platforms/proxmox#proxmox

talosctl apply-config --insecure --nodes 192.168.11.11 --file ./talos-configs/configs/controlplane.yaml

talosctl bootstrap --nodes 192.168.11.11 --endpoints 192.168.11.11 --talosconfig ./talos-configs/configs/talosconfig

rm -rf ~/.kube/*

talosctl kubeconfig --nodes 192.168.11.11 --endpoints 192.168.11.11 --talosconfig ./talos-configs/configs/talosconfig ./talos-configs/configs/config

6. Install Cilium with helm 

docs: https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium#deploy-cilium-cni
      https://docs.cilium.io/en/latest/network/servicemesh/gateway-api/gateway-api/


helm repo add cilium https://helm.cilium.io/

kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/experimental-install.yaml

helm repo update

helm upgrade --install cilium cilium/cilium --version 1.19.3 --namespace kube-system -f ./helm/cilium/cilium.values.yaml 

kubectl apply -f ./helm/cilium/resources/cilium/

6. Set up worker nodes

talosctl apply-config --insecure --nodes 192.168.11.12 --file ./talos-configs/configs/worker.yaml

talosctl apply-config --insecure --nodes 192.168.11.13 --file ./talos-configs/configs/worker.yaml

talosctl apply-config --insecure --nodes 192.168.11.14 --file ./talos-configs/configs/worker.yaml

7. set up metrics-server and kubelet-serving-cert-approver

docs: https://docs.siderolabs.com/kubernetes-guides/monitoring-and-observability/deploy-metrics-server#deploy-the-metrics-server

talosctl machineconfig patch ./talos-configs/configs/controlplane.yaml --patch @./talos-configs/patches/post-setup.yaml -o ./talos-configs/configs/controlplane.yaml

talosctl machineconfig patch ./talos-configs/configs/worker.yaml --patch @./talos-configs/patches/post-setup.yaml -o ./talos-configs/configs/worker.yaml

talosctl --talosconfig ./talos-configs/configs/talosconfig apply-config --endpoints 192.168.11.11 --nodes 192.168.11.11 --file ./talos-configs/configs/controlplane.yaml

talosctl --talosconfig ./talos-configs/configs/talosconfig apply-config --endpoints 192.168.11.12 --nodes 192.168.11.12 --file ./talos-configs/configs/worker.yaml

talosctl --talosconfig ./talos-configs/configs/talosconfig apply-config --endpoints 192.168.11.13 --nodes 192.168.11.13 --file ./talos-configs/configs/worker.yaml

talosctl --talosconfig ./talos-configs/configs/talosconfig apply-config --endpoints 192.168.11.14 --nodes 192.168.11.14 --file ./talos-configs/configs/worker.yaml

kubectl certificate approve $(kubectl get csr -o name)

kubectl apply -f https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/main/deploy/standalone-install.yaml

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

8. Setup Cert Manager

helm repo add jetstack https://charts.jetstack.io 

helm repo update

helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.20.2 -f ./helm/certmanager/certmanager.values.yaml 

kubectl apply -f ./helm/certmanager/resources/certmanager/

8. Set up longhorn

helm repo add longhorn https://charts.longhorn.io

helm repo update
  
helm upgrade --install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace --version 1.11.2 -f ./helm/longhorn/longhorn.values.yaml 

kubectl apply -f ./helm/longhorn/resources/longhorn/


 
