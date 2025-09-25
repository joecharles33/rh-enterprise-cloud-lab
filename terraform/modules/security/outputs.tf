output "sg_admin_id" {
  value = aws_security_group.admin_ingress.id
}
output "sg_intra_id" {
  value = aws_security_group.intra_vpc.id
}
output "sg_satellite_id" {
  value = aws_security_group.satellite.id
}
