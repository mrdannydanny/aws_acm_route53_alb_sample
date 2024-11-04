# security group for ALB (allow HTTPS/HTTP traffic)
resource "aws_security_group" "alb_sg" {
  name = "alb-sg"
  description = "Security group for Application Load Balancer"

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# security group for the launch template
resource "aws_security_group" "launch_template_security_group" {
  vpc_id      = var.default_vpc_id
  name        = "launch_template_security_group"
  description = "used by the ec2 instances spinned up by the ASG"

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups  = [aws_security_group.alb_sg.id] # allow traffic comming from ALB to the ec2 instances using this launch template
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

