##################################################################################
# RESOURCES
##################################################################################

resource "aws_lb" "nginx" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public-subnets[*].id

  enable_deletion_protection = false

  tags = local.common_tags
}

resource "aws_lb_target_group" "nginx" {
  name     = "${local.name_prefix}-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}

resource "aws_lb_listener" "nginx" {
  load_balancer_arn = aws_lb.nginx.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }

  tags = local.common_tags
}


resource "aws_autoscaling_attachment" "Brainwork" {
  autoscaling_group_name = aws_autoscaling_group.Brainwork.id
  lb_target_group_arn   = aws_lb_target_group.nginx.arn
}