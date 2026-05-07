THIS MODULE IS FOR CREATING PROXMOX CLOUD-INIT TEMPLATE
refs

- https://registry.terraform.io/providers/bpg/proxmox/latest/docs#api-token-authentication

WHAT DOES THIS SOLVE ?
we can programaticly create cloud-init with terraform

Requisites:
do this in proxmox server
1. Create a user for terraform in proxmox

pveum user add terraform@pve

pveum role add Terraform -privs "Realm.AllocateUser, VM.PowerMgmt, VM.GuestAgent.Unrestricted, Sys.Console, Sys.Audit, Sys.AccessNetwork, VM.Config.Cloudinit, VM.Replicate, Pool.Allocate, SDN.Audit, Realm.Allocate, SDN.Use, Mapping.Modify, VM.Config.Memory, VM.GuestAgent.FileSystemMgmt, VM.Allocate, SDN.Allocate, VM.Console, VM.Clone, VM.Backup, Datastore.AllocateTemplate, VM.Snapshot, VM.Config.Network, Sys.Incoming, Sys.Modify, VM.Snapshot.Rollback, VM.Config.Disk, Datastore.Allocate, VM.Config.CPU, VM.Config.CDROM, Group.Allocate, Datastore.Audit, VM.Migrate, VM.GuestAgent.FileWrite, Mapping.Use, Datastore.AllocateSpace, Sys.Syslog, VM.Config.Options, Pool.Audit, User.Modify, VM.Config.HWType, VM.Audit, Sys.PowerMgmt, VM.GuestAgent.Audit, Mapping.Audit, VM.GuestAgent.FileRead, Permissions.Modify"

pveum aclmod / -user terraform@pve -role Terraform

pveum user token add terraform@pve provider --privsep=0

2. Create a ssh key for terraform user on the server
do this on local development machine

ssh-keygen -t ed25519 -f ./ssh-keys/proxmox_terraform -N ""

ssh-copy-id -i ./ssh-keys/proxmox_terraform.pub root@proxmox.109lcpalhcm.crabdance.com


