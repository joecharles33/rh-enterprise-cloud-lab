data "aws_ami" "rhel" {
  count       = var.enable_satellite && var.rhel_ami_id == "" && var.rhel_ami_name_regex != "" && length(var.rhel_ami_owners) > 0 ? 1 : 0
  most_recent = true
  owners      = var.rhel_ami_owners
  filter { name = "name" values = [var.rhel_ami_name_regex] }
  filter { name = "root-device-type" values = ["ebs"] }
}

locals {
  ami_id    = var.rhel_ami_id != "" ? var.rhel_ami_id : (length(data.aws_ami.rhel) > 0 ? data.aws_ami.rhel[0].id : "")
  hostname  = "satellite.${var.internal_domain}"
  subnet_id = var.satellite_public ? var.public_subnet_id : var.private_subnet_id
  associate = var.satellite_public
}

resource "aws_instance" "satellite" {
  count                        = var.enable_satellite ? 1 : 0
  ami                          = local.ami_id
  instance_type                = var.satellite_instance_type
  subnet_id                    = local.subnet_id
  vpc_security_group_ids       = [var.sg_satellite_id]
  associate_public_ip_address  = local.associate
  key_name                     = var.key_name

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
    throughput  = 125
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-satellite", Project = "RH-Enterprise-Cloud-Lab" })

  user_data = <<-CLOUD
    #cloud-config
    hostname: ${local.hostname}
    fqdn: ${local.hostname}
  CLOUD
}

resource "aws_ebs_volume" "pulp" {
  count             = var.enable_satellite ? 1 : 0
  availability_zone = aws_instance.satellite[0].availability_zone
  size              = var.satellite_pulp_size_gb
  type              = "gp3"
  iops              = var.satellite_pulp_iops
  throughput        = var.satellite_pulp_throughput
  tags = merge(var.tags, { Name = "${var.name_prefix}-satellite-pulp" })
}

resource "aws_volume_attachment" "pulp_att" {
  count       = var.enable_satellite ? 1 : 0
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.pulp[0].id
  instance_id = aws_instance.satellite[0].id
}
