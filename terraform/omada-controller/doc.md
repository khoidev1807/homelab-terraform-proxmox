THIS MODULE IS FOR CREATING OMADA-CONTROLLER
refs

- https://registry.terraform.io/providers/bpg/proxmox/latest/docs#api-token-authentication
- https://cloud-images.ubuntu.com/

WHAT DOES THIS SOLVE ?
we can programaticly create cloud-init omada-controller with terraform


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

3. install omada-controller after server provisoned
do this in the vm

sudo apt update && sudo apt upgrade -y

sudo apt install -y openjdk-17-jre-headless jsvc curl wget

sudo apt-get install gnupg curl

curl -fsSL https://pgp.mongodb.com/server-8.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
   --dearmor

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list

sudo apt-get update

sudo apt-get install -y mongodb-org

sudo systemctl start mongod

sudo systemctl daemon-reload

sudo systemctl enable mongod

wget https://static.tp-link.com/upload/software/2026/202604/20260402/Omada_Network_Application_v6.2.0.17_linux_x64_20260331104746.deb

sudo dpkg -i ./Omada_Network_Application_v6.2.0.17_linux_x64_20260331104746.deb

sudo systemctl start tpeap

sudo systemctl enable tpeap