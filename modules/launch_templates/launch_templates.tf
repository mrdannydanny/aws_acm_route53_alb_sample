data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # canonical
  tags   = var.tags
}

resource "aws_launch_template" "launch_template_default" {
  name          = "launch_template_default"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [var.launch_template_security_group_id] # security groups 
  user_data              = filebase64("${path.module}/nginx_install.sh")
  tags                   = var.tags
}
