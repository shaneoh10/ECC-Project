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
