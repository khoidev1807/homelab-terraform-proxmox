THIS MODULE IS FOR CREATING TALOS-CLUSTER

refs 
- https://registry.terraform.io/providers/bpg/proxmox/latest/docs#api-token-authentication
- https://docs.siderolabs.com/talos/v1.13/platform-specific-installations/virtualized-platforms/proxmox#proxmox
- https://factory.talos.dev/
- https://docs.cilium.io/en/latest/network/servicemesh/gateway-api/gateway-api/

WHAT DOES THIS SOLVE ?
we can programaticly create talos cluster with one controll-plane and n worker nodes with terraform

1. Create a user for terraform in proxmox
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

- https://factory.talos.dev/

- qemu-agent (for proxmox)
- iscsi-tools (for longhorn)
- util-linux-tools (for longhorn)

4. Set up talos config with qemu-agent image latest version

talosctl gen config talos-proxmox-cluster https://192.168.11.11:6443 --output-dir ./talos-configs  --install-image factory.talos.dev/nocloud-installer-secureboot/861a91152157e97c900df9ca48fe4a26f19f19795e081386751bb7994c16800f:v1.13.0 --config-patch @./talos-configs/patches/patch.yaml  --kubernetes-version 1.36.0

5. Set up control plane node 

talosctl apply-config --insecure --nodes 192.168.11.11 --file ./talos-configs/controlplane.yaml

talosctl bootstrap --nodes 192.168.11.11 --endpoints 192.168.11.11 --talosconfig ./talos-configs/talosconfig

rm -rf ~/.kube/*

talosctl kubeconfig --nodes 192.168.11.11 --endpoints 192.168.11.11 --talosconfig ./talos-configs/talosconfig ./talos-configs/config\


6. Install Cilium with helm 


helm repo add cilium https://helm.cilium.io/

helm repo update

helm install \
    cilium \
    cilium/cilium \
    --version 1.19.3 \
    --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set kubeProxyReplacement=true \
    --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --set cgroup.autoMount.enabled=false \
    --set cgroup.hostRoot=/sys/fs/cgroup \
    --set k8sServiceHost=localhost \
    --set k8sServicePort=7445 \
    --set=gatewayAPI.enabled=true \
    --set=gatewayAPI.enableAlpn=true \
    --set=gatewayAPI.enableAppProtocol=true

kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.5.1/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.5.1/config/crd/standard/gateway.networking.k8s.io_gateways.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.5.1/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.5.1/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.5.1/config/crd/standard/gateway.networking.k8s.io_grpcroutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.5.1/config/crd/standard/gateway.networking.k8s.io_backendtlspolicies.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v1.5.1/config/crd/standard/gateway.networking.k8s.io_tlsroutes.yaml

   
6. Set up worker nodes

talosctl apply-config --insecure --nodes 192.168.11.12 --file ./talos-configs/worker.yaml

talosctl apply-config --insecure --nodes 192.168.11.13 --file ./talos-configs/worker.yaml

talosctl apply-config --insecure --nodes 192.168.11.14 --file ./talos-configs/worker.yaml

7. Set up longhorn

helm repo add longhorn https://charts.longhorn.io

helm repo update
  
helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace --version 1.9.0


