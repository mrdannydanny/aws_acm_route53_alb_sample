output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "launch_template_security_group_id" {
  value = aws_security_group.launch_template_security_group.id
}