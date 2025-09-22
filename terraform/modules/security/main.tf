resource "aws_security_group" "bastion" {
  name        = var.bastion_sg_name
  description = "Bastion access"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from admin CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
  tags = merge(var.tags, { Name = var.bastion_sg_name })
}

resource "aws_security_group" "target" {
  name        = "${var.name_prefix}-target-sg"
  description = "Target access"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
  tags = merge(var.tags, { Name = "${var.name_prefix}-target-sg" })
}

resource "aws_security_group" "aap" {
  name        = "${var.name_prefix}-aap-sg"
  description = "AAP UI/API"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from admin CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }
  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
  tags = merge(var.tags, { Name = "${var.name_prefix}-aap-sg" })
}

resource "aws_security_group" "satellite" {
  name        = "${var.name_prefix}-satellite-sg"
  description = "Satellite access"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.satellite_public ? [1] : []
    content {
      description = "HTTPS from admin CIDR (public mode)"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [var.admin_cidr]
    }
  }
  dynamic "ingress" {
    for_each = var.satellite_public ? [] : [1]
    content {
      description = "HTTPS from inside VPC (private mode)"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
    }
  }

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress { from_port = 0 to_port = 0 protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }
  tags = merge(var.tags, { Name = "${var.name_prefix}-satellite-sg" })
}
