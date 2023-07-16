resource "aws_ami_copy" "project_ami" {
  name              = "project-rhel-ecsami"
  description       = "A copy of project dev ami"
  source_ami_id     = var.source_ami_id
  source_ami_region = var.region

  tags = {
    Terraform   = "true"
    Name        = "project-rhel-ecsami"
  }
}

resource "aws_launch_configuration" "project_launch_configuration" {
  image_id                    = var.source_ami_id
  instance_type               = var.instance_type
  name_prefix                 = "project-rhel-ecsami-api-"
  key_name                    = "project_api"
  iam_instance_profile        = aws_iam_instance_profile.project_iam_instance_profile.arn
  associate_public_ip_address = "false"
  ebs_optimized               = "false"
  security_groups  = [aws_security_group.project_website.id]
  root_block_device {
    delete_on_termination = "true"
    encrypted             = "false"
    iops                  = "0"
    throughput            = "0"
    volume_size           = "10"
    volume_type           = "gp2"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "project_autoscaling_group" {
  name                      = "project-ecs-api"
  max_size                  = "2"
  min_size                  = "1"
  health_check_grace_period = "300"
  health_check_type         = "EC2"
  capacity_rebalance        = "false"
  default_cooldown          = "300"
  desired_capacity          = "1"
  enabled_metrics           = ["GroupAndWarmPoolDesiredCapacity", "GroupAndWarmPoolTotalCapacity", "GroupDesiredCapacity", "GroupInServiceCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingCapacity", "GroupPendingInstances", "GroupStandbyCapacity", "GroupStandbyInstances", "GroupTerminatingCapacity", "GroupTerminatingInstances", "GroupTotalCapacity", "GroupTotalInstances", "WarmPoolDesiredCapacity", "WarmPoolMinSize", "WarmPoolPendingCapacity", "WarmPoolTerminatingCapacity", "WarmPoolTotalCapacity", "WarmPoolWarmedCapacity"]
  force_delete              = "false"
  launch_configuration      = aws_launch_configuration.project_launch_configuration.name
  max_instance_lifetime     = "0"
  metrics_granularity       = "1Minute"
  protect_from_scale_in     = "false"

  tag {
    key                 = "Name"
    propagate_at_launch = "true"
    value               = "project-ecs-api"
  }

  vpc_zone_identifier       = [aws_subnet.project_private_subnet_1a.id, aws_subnet.project_private_subnet_1c.id]
  wait_for_capacity_timeout = "10m"

  lifecycle {
    create_before_destroy = true
  }
}