output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "public_subnet_1_id" {
  description = "The ID of the first public subnet"
  value       = aws_subnet.sn1.id
}

output "public_subnet_2_id" {
  description = "The ID of the second public subnet"
  value       = aws_subnet.sn2.id
}

output "private_subnet_1_id" {
  description = "The ID of the first private subnet"
  value       = aws_subnet.private_sn1.id
}

output "private_subnet_2_id" {
  description = "The ID of the second private subnet"
  value       = aws_subnet.private_sn2.id
}

output "alb_sg_id" {
  description = "The ID of the ALB security group"
  value       = aws_security_group.alb_sg.id
}

output "app_sg_id" {
  description = "The ID of the ECS application security group"
  value       = aws_security_group.app_sg.id
}

output "db_sg_id" {
  description = "The ID of the PostgreSQL database security group"
  value       = aws_security_group.db_sg.id
}
