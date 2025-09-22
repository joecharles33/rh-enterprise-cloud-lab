variable "name_prefix"     { type = string }
variable "vpc_id"          { type = string }
variable "vpc_cidr"        { type = string }
variable "admin_cidr"      { type = string }
variable "bastion_sg_name" { type = string }
variable "satellite_public"{ type = bool }
variable "tags"            { type = map(string), default = {} }
