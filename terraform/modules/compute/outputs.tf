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

output "pah_ips" {
  value = [
    for _, v in aws_instance.lab_nodes :
      v.private_ip
    if try(v.tags["Role"], "") == "pah" || try(v.tags["Group"], "") == "pah"
  ]
}

output "aap_db_ips" {
  value = [
    for _, v in aws_instance.lab_nodes :
      v.private_ip
    if try(v.tags["Role"], "") == "aap-db" || try(v.tags["Group"], "") == "aap-db"
  ]
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
