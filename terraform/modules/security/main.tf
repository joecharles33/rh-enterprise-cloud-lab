resource "aws_security_group" "admin_ingress" {
  name        = "${var.project}-${var.env}-admin-ingress"
  description = "Allow SSH and ICMP from admin CIDR"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from admin"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description = "ICMP echo"
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    description = "All egress"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.env}-sg-admin"
  }
}

resource "aws_security_group" "intra_vpc" {
  name        = "${var.project}-${var.env}-intra"
  description = "Allow all traffic within VPC"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.env}-sg-intra"
  }
}

resource "aws_security_group" "satellite" {
  name        = "${var.project}-${var.env}-satellite"
  description = "Satellite public access + internal control ports"
  vpc_id      = var.vpc_id

  # Public UI/content
  ingress {
    description = "HTTP"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Internal Satellite ports
  ingress {
    description = "Puppet (8140)"
    protocol    = "tcp"
    from_port   = 8140
    to_port     = 8140
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    description = "Qpid/Agent (5647)"
    protocol    = "tcp"
    from_port   = 5647
    to_port     = 5647
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    description = "Smart Proxy (9090)"
    protocol    = "tcp"
    from_port   = 9090
    to_port     = 9090
    cidr_blocks = [var.vpc_cidr, var.admin_cidr]
  }

  # SSH for admin
  ingress {
    description = "SSH admin"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    description = "All egress"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.env}-sg-satellite"
  }
}
