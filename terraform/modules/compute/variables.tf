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
