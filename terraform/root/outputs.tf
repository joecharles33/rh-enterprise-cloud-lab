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
