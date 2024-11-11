### declaring default subnets to use on autoscaling group and alb
data "aws_subnets" "example" {
  filter {
    name = "vpc-id"
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
  subnets         = [for subnet in data.aws_subnet.example : subnet.id]
  security_groups = [var.alb_security_group_id]

  access_logs {
    bucket  = var.bucket
    prefix  = var.bucket_prefix
    enabled = true
  }

  tags = var.tags
}

# listener for HTTPS with ACM certificate
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"                                    # could be a foward, redirect to specific url, fixed response
    target_group_arn = aws_lb_target_group.target_group_default.arn # you can have multiple target groups as targets and specify weights (blue/green) - todo
  }
  tags = var.tags
}

#todo blue/green later on:

/*
resource "aws_alb_listener" "https" {
  load_balancer_arn = var.alb_arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.security_policy
  certificate_arn   = var.ssl_certificate

  default_action {
    type = "forward"

    forward {
      target_group {
        arn    = var.target_group_arn_1
        weight = 1
      }

      target_group {
        arn    = var.target_group_arn_2
        weight = 1
      }
    }
  }
}
*/

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  tags = var.tags
}


# creates the default target group
resource "aws_lb_target_group" "target_group_default" {
  name                          = "target-group-default"
  port                          = 80
  protocol                      = "HTTP"
  vpc_id                        = var.vpc_id
  load_balancing_algorithm_type = "round_robin" # options: least_outstanding_requests (less busy instance will receive the request), weighted_random and round_robin (default)
  tags                          = var.tags
}

# creates an auto scaling group
resource "aws_autoscaling_group" "asg-default" {
  name             = "asg-default"
  min_size         = 1
  max_size         = 3
  desired_capacity = 1

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

# autoscaling policy to increase the amount of instances
resource "aws_autoscaling_policy" "increase_ec2" {
  name                   = "increase-ec2"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg-default.name
  policy_type            = "SimpleScaling"

}

# autoscaling policy to decrease the amount of instances
resource "aws_autoscaling_policy" "reduce_ec2" {
  name                   = "reduce-ec2"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg-default.name
  policy_type            = "SimpleScaling"
}


resource "aws_cloudwatch_metric_alarm" "increase_ec2_alarm" {
  alarm_name          = "increase-ec2-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  /*
    Number of periods over which the alarm condition must be met to trigger
    the alarm. It is set to 2, meaning the CPU utilization must remain above
    the threshold for two consecutive periods
  */
  evaluation_periods        = 2
  metric_name               = "CPUUtilization" # Name of the metric to monitor. Here, it's "CPUUtilization", indicating the CPU utilization metric of EC2 instances
  namespace                 = "AWS/EC2"
  period                    = 120       # The alarm evaluates CPU utilization data over a period of 120 seconds (2 minutes)  
  statistic                 = "Average" # Average CPU utilization
  threshold                 = 70        # Threshold value that, when crossed, triggers the alarm
  alarm_description         = "This metric monitors ec2 cpu utilization, if it goes above 70% for 2 periods it will trigger an alarm."
  insufficient_data_actions = []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg-default.name
  }

  /*
    Actions to take when the alarm state changes to "ALARM".
    When the alarm triggers, it will send notifications to the SNS topic
    and execute the specified Auto Scaling policy.
  */
  alarm_actions = [
    #aws_sns_topic.my_sns_topic.arn,
    aws_autoscaling_policy.increase_ec2.arn
  ]
}

resource "aws_cloudwatch_metric_alarm" "reduce_ec2_alarm" {
  alarm_name                = "reduce-ec2-alarm"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 40
  alarm_description         = "This metric monitors ec2 cpu utilization, if it goes below 40% for 2 periods it will trigger an alarm."
  insufficient_data_actions = []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg-default.name
  }

  alarm_actions = [
    #aws_sns_topic.my_sns_topic.arn,
    aws_autoscaling_policy.reduce_ec2.arn
  ]
}

/* sns topic to send an email in case alarm triggers */

/*
resource "aws_sns_topic" "my_sns_topic" {
  name = "cpu_alarm_topic"
}

resource "aws_sns_topic_subscription" "my_sns_topic_subscription" {
  topic_arn = aws_sns_topic.my_sns_topic.arn
  protocol  = "email"
  endpoint  = "example@gmail.com"
}
*/