variable "name_prefix"           { type = string }
variable "key_name"              { type = string }
variable "linux_user"            { type = string }
variable "bastion_user"          { type = string }
variable "vpc_id"                { type = string }
variable "public_subnet_id"      { type = string }
variable "private_subnet_id"     { type = string }
variable "sg_bastion_id"         { type = string }
variable "sg_target_id"          { type = string }
variable "sg_aap_id"             { type = string }
variable "rhel_ami_id"           { type = string, default = "" }
variable "rhel_ami_owners"       { type = list(string), default = [] }
variable "rhel_ami_name_regex"   { type = string, default = "" }
variable "bastion_instance_type" { type = string }
variable "target_instance_type"  { type = string }
variable "count_rhel_targets"    { type = number }
variable "enable_aap"            { type = bool, default = false }
variable "aap_controller_type"   { type = string }
variable "aap_hub_type"          { type = string }
variable "aap_eda_type"          { type = string }
variable "internal_domain"       { type = string }
variable "tags"                  { type = map(string), default = {} }
