variable "enable_satellite"        { type = bool }
variable "satellite_public"        { type = bool }
variable "name_prefix"             { type = string }
variable "vpc_id"                  { type = string }
variable "public_subnet_id"        { type = string }
variable "private_subnet_id"       { type = string }
variable "sg_bastion_id"           { type = string }
variable "sg_satellite_id"         { type = string }
variable "key_name"                { type = string }
variable "linux_user"              { type = string }
variable "rhel_ami_id"             { type = string, default = "" }
variable "rhel_ami_owners"         { type = list(string), default = [] }
variable "rhel_ami_name_regex"     { type = string, default = "" }
variable "satellite_instance_type" { type = string }
variable "satellite_pulp_size_gb"  { type = number }
variable "satellite_pulp_iops"     { type = number }
variable "satellite_pulp_throughput" { type = number }
variable "internal_domain"         { type = string }
variable "admin_cidr"              { type = string }
variable "vpc_cidr"                { type = string }
variable "tags"                    { type = map(string), default = {} }
