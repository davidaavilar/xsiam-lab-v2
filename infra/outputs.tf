## VMs

output "ssh_file_entries" {
  value = join("\n\n", [
    for name, inst in aws_instance.jumpbox : <<-EOT
      Host ${name}
        HostName ${aws_eip.jumpbox[name].public_ip}
        User ${local.jumpbox[name].user}
        IdentityFile ~/Documents/${var.ssh_key_name}.pem
        IdentitiesOnly yes
    EOT
  ])
  description = "modify vim ~/.ssh/config"
}

output "jumpbox_access" {
  value = nonsensitive({
    for name, inst in aws_instance.jumpbox :
    name => {
      public_ip  = aws_eip.jumpbox[name].public_ip
      private_ip = inst.private_ip
      user       = local.jumpbox[name].user
    }
  })
}

# # FWS

output "vmseries_public_ips" {
  description = "Map of public IPs created within `vmseries` module instances."
  value       = nonsensitive({ for k, v in module.vmseries : k => v.public_ips })
}

output "vmseries_private_ips" {
  value = {
    for vm_name, vm in module.vmseries :
    vm_name => {
      for iface_name, iface in vm.interfaces :
      iface_name => iface.private_ip
    }
  }
}

output "vm_access_map" {
  value = merge(
    {
      for name, vm in aws_instance.vms :
      name => {
        private_ip = vm.private_ip
        user       = local.vms[name].user
      }
    },
    {
      for name, vm in aws_instance.xsiam_components :
      name => {
        private_ip = vm.private_ip
        user       = local.xsiam_components[name].user
      }
    }
  )
}


output "broker_vm_bucket_name" {
  value = var.broker_vm ? module.broker_vm[0].broker_vm_bucket_name : null
}

output "broker_vm_cp" {
  value = var.broker_vm ? "aws s3 cp ${var.broker_vm_key} s3://${module.broker_vm[0].broker_vm_bucket_name}/${var.broker_vm_key}" : null
}

output "broker_vm_import" {
  value = var.broker_vm ? "aws ec2 import-snapshot --description '<Cortex XSIAM Broker VM' --disk-container 'file://configuration.json'" : null
}

output "broker_vm_import_validate" {
  value = var.broker_vm ? "aws ec2 describe-import-snapshot-tasks --import-task-ids <IMPORT_SNAPSHOT_ID>" : null
}

output "broker_vm_register_ami" {
  value = var.broker_vm ? "aws ec2 register-image --name 'broker-vm-ami' --architecture x86_64 --root-device-name /dev/sda1 --virtualization-type hvm --boot-mode legacy-bios --ena-support --block-device-mappings 'DeviceName=/dev/sda1,Ebs={SnapshotId=snap-XXXXXXX,VolumeSize=480,VolumeType=gp3,Iops=3000,Throughput=125,DeleteOnTermination=true}'" : null
}