output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "target_private_ips" {
  value = [for i in aws_instance.target : i.private_ip]
}

output "aap_private_ips" {
  value = concat(
    [for i in aws_instance.aap_controller : i.private_ip],
    [for i in aws_instance.aap_hub : i.private_ip],
    [for i in aws_instance.aap_eda : i.private_ip]
  )
}
