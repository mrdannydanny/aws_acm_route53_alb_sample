### declaring default subnets to use on autoscaling group and alb
data "aws_subnets" "example" {
  filter {
    name   = "vpc-id"
    #values = [data.aws_vpc.selected.id]
    values = [var.vpc_id]
  }
}

data "aws_subnet" "example" {
  for_each = toset(data.aws_subnets.example.ids)
  id       = each.value
}

### alb 
resource "aws_lb" "main" {
  name               = "my-app-lb"
  load_balancer_type = "application"

  # Use default public subnets
  subnets            = [for subnet in data.aws_subnet.example : subnet.id]
  security_groups    = [var.alb_security_group_id]

  tags = {
    Name = "app-alb"
  }
}

# listener for HTTPS with ACM certificate
resource "aws_lb_listener" "main" {
  load_balancer_arn  = aws_lb.main.arn
  port               = 443
  protocol           = "HTTPS"
  ssl_policy         = "ELBSecurityPolicy-2016-08"
  certificate_arn    = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_default.arn
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.main.arn
  port               = 80
  protocol           = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


# creates the default target group
resource "aws_lb_target_group" "target_group_default" {
  name     = "target-group-default"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

# creates an auto scaling group
resource "aws_autoscaling_group" "asg-default" {
  name                 = "asg-default"
  min_size             = 1
  max_size             = 2
  desired_capacity     = 2

  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }

  vpc_zone_identifier = [for s in data.aws_subnet.example : s.id]
  target_group_arns   = [aws_lb_target_group.target_group_default.arn] # all ec2 instances spinned up by this asg will be associated with the target group

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [load_balancers, target_group_arns]
  }

  wait_for_capacity_timeout = "15m"
}

