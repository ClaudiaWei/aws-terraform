resource "aws_ecs_cluster" "project_api" {
  name               = "project_api"
}

resource "aws_ecs_cluster_capacity_providers" "project_api" {
  cluster_name = aws_ecs_cluster.project_api.name
  capacity_providers = [aws_ecs_capacity_provider.project_api.name]
  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.project_api.name
  }
}

resource "aws_ecs_capacity_provider" "project_api" {
  name = "project_api"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.project_autoscaling_group.arn
  }
}

resource "aws_ecs_task_definition" "project_api" {
  container_definitions = <<TASK_DEFINITION
[
  {
    "cpu": 0,
    "environment": [ ],
    "essential": true,
    "image": "",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/aws/ecs/project_api",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "project_api"
      }
    },
    "memoryReservation": 1024,
    "mountPoints": [],
    "name": "project_api",
    "portMappings": [
      {
        "containerPort": 5000,
        "hostPort": 0,
        "protocol": "tcp"
      }
    ],
    "privileged": false,
    "volumesFrom": []
  }
]
TASK_DEFINITION

  family                   = "project_api"
  requires_compatibilities = ["EC2"]
}

resource "aws_ecs_service" "project_api" {
  name = "project_api"
  cluster = aws_ecs_cluster.project_api.id
  deployment_circuit_breaker {
    enable   = "false"
    rollback = "false"
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_maximum_percent         = "200"
  deployment_minimum_healthy_percent = "50"
  desired_count                      = "1"
  enable_ecs_managed_tags            = "true"
  enable_execute_command             = "false"
  health_check_grace_period_seconds  = "0"
  launch_type                        = "EC2"

  load_balancer {
    container_name   = "project_api"
    container_port   = "5000"
    target_group_arn = aws_lb_target_group.project_api_target_group.arn
  }

  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  ordered_placement_strategy {
    field = "instanceId"
    type  = "spread"
  }

  scheduling_strategy = "REPLICA"
  task_definition     = aws_ecs_task_definition.project_api.arn
}
