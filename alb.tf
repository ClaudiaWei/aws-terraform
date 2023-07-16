resource "aws_lb" "project_alb" {
  access_logs {
    bucket  = "project-alb-access-log-${var.env}"
    enabled = "true"
  }

  drop_invalid_header_fields = false
  internal                   = false
  ip_address_type            = "ipv4"
  load_balancer_type         = "application"
  name                       = "project-alb"
  security_groups            = [aws_security_group.project_alb.id]
  subnets                    = [aws_subnet.project_public_subnet_1a.id, aws_subnet.project_public_subnet_1c.id]
  tags = {
    Terraform   = "true"
    Name        = "project-alb"
  }
}

resource "aws_lb_target_group" "project_api_target_group" {
  name                  = "project-api"
  port                  = "80"
  protocol              = "HTTP"
  protocol_version      = "HTTP1"
  slow_start            = "0"
  target_type           = "instance"
  vpc_id                = aws_vpc.project_vpc.id

  health_check {
    enabled             = "true"
    healthy_threshold   = "5"
    interval            = "30"
    matcher             = "404"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "5"
    unhealthy_threshold = "2"
  }

  stickiness {
    cookie_duration = "86400"
    enabled         = "false"
    type            = "lb_cookie"
  }
}

resource "aws_lb_listener" "project_lb_listener_http" {
  load_balancer_arn = aws_lb.project_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.project_api_target_group.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "project_lb_listener_https" {
  load_balancer_arn = aws_lb.project_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy"
  certificate_arn   = var.alb_certificate_arn

  default_action {
    order            = "1"
    target_group_arn = aws_lb_target_group.project_api_target_group.arn
    type             = "forward"
  }
}




