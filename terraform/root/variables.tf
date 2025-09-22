variable "region"               { type = string }
variable "name_prefix"          { type = string }
variable "vpc_cidr"             { type = string }
variable "public_subnet_cidr"   { type = string }
variable "private_subnet_cidr"  { type = string }
variable "internal_domain"      { type = string }
variable "key_name"             { type = string }
variable "admin_cidr"           { type = string }
variable "linux_user"           { type = string }
variable "bastion_user"         { type = string }

variable "rhel_ami_id"          { type = string, default = "" }
variable "rhel_ami_owners"      { type = list(string), default = [] }
variable "rhel_ami_name_regex"  { type = string, default = "" }

variable "count_rhel_targets"   { type = number, default = 2 }
variable "enable_aap"           { type = bool,   default = false }
variable "enable_satellite"     { type = bool,   default = true }
variable "satellite_public"     { type = bool,   default = false }

variable "bastion_instance_type"   { type = string, default = "t3.medium" }
variable "target_instance_type"    { type = string, default = "t3.large"  }
variable "aap_controller_type"     { type = string, default = "t3.xlarge" }
variable "aap_hub_type"            { type = string, default = "t3.large"  }
variable "aap_eda_type"            { type = string, default = "t3.large"  }
variable "satellite_instance_type" { type = string, default = "m6i.2xlarge" }

variable "satellite_pulp_size_gb"    { type = number, default = 600 }
variable "satellite_pulp_iops"       { type = number, default = 6000 }
variable "satellite_pulp_throughput" { type = number, default = 250 }

variable "tags" {
  type = map(string)
  default = {}
}
