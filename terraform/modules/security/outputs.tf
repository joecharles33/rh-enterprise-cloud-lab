output "sg_bastion_id"   { value = aws_security_group.bastion.id }
output "sg_target_id"    { value = aws_security_group.target.id }
output "sg_aap_id"       { value = aws_security_group.aap.id }
output "sg_satellite_id" { value = aws_security_group.satellite.id }
