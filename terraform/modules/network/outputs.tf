output "vpc_id" {
  value = aws_vpc.this.id
}
output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}
output "subnet_public_id" {
  value = aws_subnet.public_a.id
}
output "subnet_private_id" {
  value = aws_subnet.private_a.id
}
