locals {
  prefix = "${var.project}-${var.env}"

  node_instances = flatten([
    for gname, gdef in var.node_groups : [
      for i in range(gdef.count) : {
        name          = format("%s-%s-%02d", local.prefix, gname, i + 1)
        group         = gname
        role          = gdef.role
        instance_type = gdef.instance_type
        subnet_type   = gdef.subnet_type
        subnet_id     = gdef.subnet_type == "public" ? var.subnet_public_id : var.subnet_private_id
        public        = gdef.subnet_type == "public"
      }
    ]
  ])

  satellite_nodes = [
    for n in local.node_instances : n if n.role == "satellite"
  ]

  other_nodes = [
    for n in local.node_instances : n if n.role != "satellite"
  ]
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.rhel9.id
  instance_type               = var.bastion_instance_type
  subnet_id                   = var.subnet_public_id
  vpc_security_group_ids      = [var.sg_admin_id, var.sg_intra_id]
  associate_public_ip_address = true
  key_name                    = var.key_pair_name

  user_data = templatefile("${path.module}/templates/bootstrap.tpl", {
    hostname = "${local.prefix}-bastion"
    role     = "bastion"
    project  = var.project
    env      = var.env
  })

  tags = {
    Name = "${local.prefix}-bastion"
    Role = "bastion"
  }
}

resource "aws_instance" "satellite" {
  for_each = { for n in local.satellite_nodes : n.name => n }

  ami                         = data.aws_ami.rhel9.id
  instance_type               = each.value.instance_type
  subnet_id                   = var.subnet_public_id
  vpc_security_group_ids      = [var.sg_satellite_id, var.sg_admin_id, var.sg_intra_id]
  associate_public_ip_address = true
  key_name                    = var.key_pair_name

  user_data = templatefile("${path.module}/templates/bootstrap.tpl", {
    hostname = each.key
    role     = "satellite"
    project  = var.project
    env      = var.env
  })

  tags = {
    Name = each.key
    Role = "satellite"
  }
}

resource "aws_eip" "satellite" {
  for_each = var.satellite_use_eip ? aws_instance.satellite : {}
  domain   = "vpc"

  tags = {
    Name = "${each.key}-eip"
  }
}

resource "aws_eip_association" "satellite" {
  for_each      = var.satellite_use_eip ? aws_instance.satellite : {}
  instance_id   = aws_instance.satellite[each.key].id
  allocation_id = aws_eip.satellite[each.key].id
}

resource "aws_instance" "lab_nodes" {
  for_each = { for n in local.other_nodes : n.name => n }

  ami                         = data.aws_ami.rhel9.id
  instance_type               = each.value.instance_type
  subnet_id                   = each.value.subnet_id
  vpc_security_group_ids      = [var.sg_intra_id, var.sg_admin_id]
  associate_public_ip_address = each.value.public
  key_name                    = var.key_pair_name

  user_data = templatefile("${path.module}/templates/bootstrap.tpl", {
    hostname = each.key
    role     = each.value.role
    project  = var.project
    env      = var.env
  })

  tags = {
    Name = each.key
    Role = each.value.role
  }
}
