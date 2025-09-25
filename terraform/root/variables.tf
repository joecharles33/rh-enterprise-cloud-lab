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
