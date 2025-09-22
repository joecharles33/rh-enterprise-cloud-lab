output "satellite_private_ip" { value = try(aws_instance.satellite[0].private_ip, null) }
output "satellite_public_ip"  { value = try(aws_instance.satellite[0].public_ip, null) }
output "satellite_hostname"   { value = "satellite.${var.internal_domain}" }
