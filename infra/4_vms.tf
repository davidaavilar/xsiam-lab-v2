locals {
  vms = {
    "${var.name_prefix}-windows-server" = {
      deploy  = var.windows_server_deploy
      ami     = data.aws_ami.windows_server.id
      type    = "t3.medium"
      user    = "Administrator"
      volume  = 50
      network = { subnet = "vlan1", public_ip = false } # Always Public IP is FALSE
      user_data = null
    }
    "${var.name_prefix}-ubuntu" = {
      deploy  = var.linux_deploy
      ami     = data.aws_ami.ubuntu2204.id
      type    = "t3.small"
      user    = "ubuntu"
      volume  = 30
      network = { subnet = "vlan1", public_ip = false } # Always Public IP is FALSE
      user_data = null
    }
    "${var.name_prefix}-kali" = {
      deploy  = var.kali_deploy
      ami     = data.aws_ami.kali.id
      type    = "t3.small"
      user    = "kali"
      volume  = 30
      network = { subnet = "vlan2", public_ip = false } # Always Public IP is FALSE
      user_data = file("${path.module}/user_data_kali.sh")
    }
  }
}


resource "aws_instance" "vms" {
  for_each = {
    for k, v in local.vms :
    k => v if v.deploy && v.ami != null
  }

  ami                    = each.value.ami
  instance_type          = each.value.type
  key_name               = var.ssh_key_name
  vpc_security_group_ids = try([module.vpc[var.vpc_name].security_group_ids["vmseries_traffic"]], [])
  ebs_optimized          = true
  subnet_id              = values(module.subnet_sets["${var.vpc_name}-${var.name_prefix}-${each.value.network.subnet}"].subnets)[0].id

  user_data = each.value.user_data
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = each.value.volume
    delete_on_termination = true
    encrypted             = true
  }

  lifecycle {
    ignore_changes = [ami]
  }

  tags = merge(
    var.global_tags,
    {
      Name = each.key
    }
  )
}