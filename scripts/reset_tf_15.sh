#!/usr/bin/env bash
set -euo pipefail

# Repo root sanity check
test -d terraform/root || { echo "Run from repo root (where terraform/ exists)"; exit 1; }

# Clean stale env-level provider/vars that fight the root module
rm -f terraform/envs/dev/provider.tf terraform/envs/dev/variables.tf || true

# Ensure module dirs exist fresh
rm -rf terraform/modules/{network,security,compute}
mkdir -p terraform/modules/{network,security,compute}/templates
mkdir -p terraform/root

# ---------- terraform/root ----------
cat > terraform/root/backend.tf <<'EOF'
terraform {
  backend "s3" {}
}
EOF

cat > terraform/root/versions.tf <<'EOF'
terraform {
  required_version = ">= 1.5.0, < 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF

cat > terraform/root/providers.tf <<'EOF'
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.env
      ManagedBy   = "terraform"
    }
  }
}
EOF

cat > terraform/root/variables.tf <<'EOF'
variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "project" {
  type        = string
  description = "Project prefix"
  default     = "rh-enterprise-cloud-lab"
}

variable "env" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "admin_cidr" {
  type        = string
  description = "Your /32 public IP for SSH + ICMP (e.g., 1.2.3.4/32)"
}

variable "key_pair_name" {
  type        = string
  description = "Existing EC2 key pair name"
}

variable "bastion_instance_type" {
  type        = string
  description = "Bastion instance type"
  default     = "t3.micro"
}

variable "node_groups" {
  description = "Map of node groups: count, instance_type, role (ansible|eda|satellite|rhel), subnet_type (public|private)"
  type = map(object({
    count         = number
    instance_type = string
    role          = string
    subnet_type   = string
  }))

  # Safe default set matching your lab
  default = {
    ansible = {
      count         = 1
      instance_type = "t3.large"
      role          = "ansible"
      subnet_type   = "private"
    }
    eda = {
      count         = 1
      instance_type = "t3.large"
      role          = "eda"
      subnet_type   = "private"
    }
    satellite = {
      count         = 1
      instance_type = "m6i.2xlarge"
      role          = "satellite"
      subnet_type   = "public"
    }
    rhel = {
      count         = 4
      instance_type = "t3.large"
      role          = "rhel"
      subnet_type   = "private"
    }
  }
}
EOF

cat > terraform/root/main.tf <<'EOF'
module "network" {
  source              = "../modules/network"
  vpc_cidr            = "10.60.0.0/16"
  public_subnet_cidr  = "10.60.1.0/24"
  private_subnet_cidr = "10.60.2.0/24"
  az                  = "${var.aws_region}a"

  project = var.project
  env     = var.env
}

module "security" {
  source     = "../modules/security"
  vpc_id     = module.network.vpc_id
  vpc_cidr   = module.network.vpc_cidr
  admin_cidr = var.admin_cidr

  project = var.project
  env     = var.env
}

module "compute" {
  source = "../modules/compute"

  project               = var.project
  env                   = var.env
  aws_region            = var.aws_region
  key_pair_name         = var.key_pair_name
  bastion_instance_type = var.bastion_instance_type

  subnet_public_id  = module.network.subnet_public_id
  subnet_private_id = module.network.subnet_private_id

  sg_admin_id     = module.security.sg_admin_id
  sg_intra_id     = module.security.sg_intra_id
  sg_satellite_id = module.security.sg_satellite_id

  node_groups       = var.node_groups
  satellite_use_eip = true
}
EOF

cat > terraform/root/outputs.tf <<'EOF'
output "vpc_id" {
  value       = module.network.vpc_id
  description = "VPC ID"
}

output "bastion_public_ip" {
  value       = module.compute.bastion_public_ip
  description = "Bastion public IP"
}

output "bastion_public_dns" {
  value       = module.compute.bastion_public_dns
  description = "Bastion public DNS"
}

output "satellite_public_ips" {
  value       = module.compute.satellite_public_ips
  description = "Satellite public IPs (EIP if enabled)"
}

output "satellite_private_ips" {
  value       = module.compute.satellite_private_ips
  description = "Satellite private IPs"
}

output "ansible_controller_ips" {
  value       = module.compute.ansible_controller_ips
  description = "Ansible controller private IPs"
}

output "eda_ips" {
  value       = module.compute.eda_ips
  description = "Ansible EDA private IPs"
}

output "rhel_generic_ips" {
  value       = module.compute.rhel_generic_ips
  description = "Generic RHEL private IPs"
}

output "all_nodes_by_name" {
  value       = module.compute.node_ips
  description = "All nodes (name => {private_ip, public_ip, role})"
}
EOF

# ---------- modules/network ----------
cat > terraform/modules/network/variables.tf <<'EOF'
variable "vpc_cidr" {
  type = string
}
variable "public_subnet_cidr" {
  type = string
}
variable "private_subnet_cidr" {
  type = string
}
variable "az" {
  type = string
}
variable "project" {
  type = string
}
variable "env" {
  type = string
}
EOF

cat > terraform/modules/network/main.tf <<'EOF'
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project}-${var.env}-vpc"
    Project     = var.project
    Environment = var.env
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}-${var.env}-igw"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.az
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-${var.env}-public-a"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.az

  tags = {
    Name = "${var.project}-${var.env}-private-a"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project}-${var.env}-nat-eip"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  depends_on    = [aws_internet_gateway.this]

  tags = {
    Name = "${var.project}-${var.env}-nat"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}-${var.env}-rtb-public"
  }
}

resource "aws_route" "public_to_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}-${var.env}-rtb-private"
  }
}

resource "aws_route" "private_to_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}
EOF

cat > terraform/modules/network/outputs.tf <<'EOF'
output "vpc_id" {
  value = aws_vpc.this.id
}
output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}
output "subnet_public_id" {
  value = aws_subnet.public_a.id
}
output "subnet_private_id" {
  value = aws_subnet.private_a.id
}
EOF

# ---------- modules/security ----------
cat > terraform/modules/security/variables.tf <<'EOF'
variable "vpc_id" {
  type = string
}
variable "vpc_cidr" {
  type = string
}
variable "admin_cidr" {
  type = string
}
variable "project" {
  type = string
}
variable "env" {
  type = string
}
EOF

cat > terraform/modules/security/main.tf <<'EOF'
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
EOF

cat > terraform/modules/security/outputs.tf <<'EOF'
output "sg_admin_id" {
  value = aws_security_group.admin_ingress.id
}
output "sg_intra_id" {
  value = aws_security_group.intra_vpc.id
}
output "sg_satellite_id" {
  value = aws_security_group.satellite.id
}
EOF

# ---------- modules/compute ----------
cat > terraform/modules/compute/variables.tf <<'EOF'
variable "project" {
  type = string
}
variable "env" {
  type = string
}
variable "aws_region" {
  type = string
}
variable "key_pair_name" {
  type = string
}
variable "bastion_instance_type" {
  type = string
}

variable "subnet_public_id" {
  type = string
}
variable "subnet_private_id" {
  type = string
}

variable "sg_admin_id" {
  type = string
}
variable "sg_intra_id" {
  type = string
}
variable "sg_satellite_id" {
  type = string
}

variable "satellite_use_eip" {
  type        = bool
  default     = true
  description = "Attach an Elastic IP to Satellite for stable public address"
}

variable "node_groups" {
  type = map(object({
    count         = number
    instance_type = string
    role          = string
    subnet_type   = string
  }))
}
EOF

cat > terraform/modules/compute/amis.tf <<'EOF'
data "aws_ami" "rhel9" {
  most_recent = true
  owners      = ["309956199498"]  # Red Hat

  filter {
    name   = "name"
    values = ["RHEL-9.*_HVM-*-x86_64-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
EOF

cat > terraform/modules/compute/templates/bootstrap.tpl <<'EOF'
#cloud-config
hostname: ${hostname}
fqdn: ${hostname}.internal
package_update: true
package_upgrade: false
packages:
  - git
  - jq
  - curl
  - unzip
  - python3
  - podman
  - tmux
  - tree
  - bind-utils
write_files:
  - path: /etc/motd
    permissions: '0644'
    content: |
      Welcome to ${hostname} (${role}) - ${project}-${env}
runcmd:
  - yum -y install insights-client || true
  - echo "ROLE=${role}" > /etc/lab-role
  - echo "PROJECT=${project}" > /etc/lab-project
  - echo "ENV=${env}" > /etc/lab-env
EOF

cat > terraform/modules/compute/main.tf <<'EOF'
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
EOF

cat > terraform/modules/compute/outputs.tf <<'EOF'
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_public_dns" {
  value = aws_instance.bastion.public_dns
}

output "satellite_public_ips" {
  value = {
    for k, v in aws_instance.satellite : k => (
      try(aws_eip_association.satellite[k].public_ip, v.public_ip)
    )
  }
}

output "satellite_private_ips" {
  value = {
    for k, v in aws_instance.satellite : k => v.private_ip
  }
}

output "ansible_controller_ips" {
  value = [
    for _, v in aws_instance.lab_nodes : v.private_ip if v.tags["Role"] == "ansible"
  ]
}

output "eda_ips" {
  value = [
    for _, v in aws_instance.lab_nodes : v.private_ip if v.tags["Role"] == "eda"
  ]
}

output "rhel_generic_ips" {
  value = [
    for _, v in aws_instance.lab_nodes : v.private_ip if v.tags["Role"] == "rhel"
  ]
}

output "node_ips" {
  value = merge(
    { for name, inst in aws_instance.lab_nodes : name => {
        private_ip = inst.private_ip
        public_ip  = inst.public_ip
        role       = inst.tags["Role"]
      }
    },
    { for name, inst in aws_instance.satellite : name => {
        private_ip = inst.private_ip
        public_ip  = try(aws_eip_association.satellite[name].public_ip, inst.public_ip)
        role       = "satellite"
      }
    }
  )
}
EOF

echo "Terraform files reset for TF 1.5.x"

