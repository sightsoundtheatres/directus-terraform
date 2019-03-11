# Providers

provider "aws" {
  region = "${var.aws_region}"
}

# Data Sources

data "aws_caller_identity" "main" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "main" {
  id = "${var.vpc_id}"
}

data "aws_s3_bucket" "main" {
  bucket = "${var.s3_bucket_name}"
}

data "template_file" "userdata" {
  template = "${file("${path.module}/userdata.tpl")}"

  vars {
    ecs_cluster_id = "${aws_ecs_cluster.main.id}"
  }
}

# Subnets

resource "aws_subnet" "main" {
  count = 3

  vpc_id                          = "${data.aws_vpc.main.id}"
  availability_zone               = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block                      = "${cidrsubnet(data.aws_vpc.main.cidr_block, 4, 4 + count.index)}"
  ipv6_cidr_block                 = "${cidrsubnet(data.aws_vpc.main.ipv6_cidr_block, 8, 16 + count.index)}"
  assign_ipv6_address_on_creation = true

  tags {
    Name        = "${var.prefix}-${var.aws_region}-WEB${format("%02d", count.index + 1)}"
    Environment = "CMS"
  }
}

# Security Groups

resource "aws_security_group" "main" {
  name   = "${var.prefix}-${var.aws_region}-WEB"
  vpc_id = "${data.aws_vpc.main.id}"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${var.lb_sg_id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  tags {
    Name        = "${var.prefix}-${var.aws_region}-WEB"
    Environment = "CMS"
  }
}

# ECS Clusters

resource "aws_ecs_cluster" "main" {
  name = "${var.prefix}-${var.aws_region}"
}

# ECS Services

resource "aws_ecs_service" "main" {
  name            = "${var.prefix}-${var.aws_region}-DirectusAPI"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.main.arn}"
  desired_count   = "${var.min_task_count}"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = ["${aws_security_group.main.*.id}"]
    subnets          = ["${aws_subnet.main.*.id}"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = "${var.lb_tg_id}"
    container_name   = "${var.prefix}-${var.aws_region}-DirectusAPI"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = ["desired_count"]
  }
}

# ECS Task Definitions

resource "aws_ecs_task_definition" "main" {
  family                   = "${var.prefix}-${var.aws_region}-DirectusAPI-TD"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  task_role_arn            = "${aws_iam_role.ecs_service.arn}"
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.main.account_id}:role/ecsTaskExecutionRole"

  container_definitions = <<DEFINITION
[
  {
    "name": "${var.prefix}-${var.aws_region}-DirectusAPI",
    "image": "${var.docker_image}",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "protocol": "tcp"
      }
    ],
    "environment": [
      {"name": "DATABASE_HOST", "value": "${var.db_endpoint}"},
      {"name": "DATABASE_NAME", "value": "${var.db_name}"},
      {"name": "DATABASE_USERNAME", "value": "${var.db_username}"},
      {"name": "DATABASE_PASSWORD", "value": "${var.db_password}"},
      {"name": "STORAGE_ADAPTER", "value": "s3"},
      {"name": "STORAGE_ROOT", "value": "www/uploads/"},
      {"name": "STORAGE_ROOT_URL", "value": "https://${var.cdn_domain_name}/www/uploads"},
      {"name": "STORAGE_THUMB_URL", "value": "www/thumbs/"},
      {"name": "STORAGE_REGION", "value": "${var.aws_region}"},
      {"name": "STORAGE_BUCKET", "value": "${var.s3_bucket_name}"},
      {"name": "ADMIN_EMAIL", "value": "admin@example.com"}
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/${lower(var.prefix)}/${var.aws_region}-DirectusAPI",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION
}

resource "aws_iam_role" "ecs_service" {
  name               = "${var.prefix}-${var.aws_region}-DirectusAPI"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_assume_role.json}"
}

resource "aws_iam_role_policy" "ecs_service" {
  name   = "${var.prefix}-${var.aws_region}-DirectusAPI"
  policy = "${data.aws_iam_policy_document.ecs_service.json}"
  role   = "${aws_iam_role.ecs_service.name}"
}

data "aws_iam_policy_document" "ecs_service" {
  statement {
    actions = [
      "s3:*",
    ]

    resources = [
      "${data.aws_s3_bucket.main.arn}",
      "${data.aws_s3_bucket.main.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "ecs-tasks.amazonaws.com",
      ]
    }
  }
}

# CloudWatch Logs

resource "aws_cloudwatch_log_group" "main" {
  name              = "/${lower(var.prefix)}/${var.aws_region}-DirectusAPI"
  retention_in_days = "14"
}

# Auto Scaling Groups

resource "aws_appautoscaling_target" "main" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = "${var.min_task_count}"
  max_capacity       = "${var.max_task_count}"
}

resource "aws_appautoscaling_policy" "up" {
  name               = "${var.prefix}-${var.aws_region}-DirectusAPI-ScaleUp"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 200
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = ["aws_appautoscaling_target.main"]
}

resource "aws_appautoscaling_policy" "down" {
  name               = "${var.prefix}-${var.aws_region}-DirectusAPI-ScaleDown"
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 200
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = ["aws_appautoscaling_target.main"]
}

resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  alarm_name          = "${var.prefix}-${var.aws_region}-HighCPU"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "65"

  dimensions {
    ClusterName = "${aws_ecs_cluster.main.name}"
    ServiceName = "${aws_ecs_service.main.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.up.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "service_cpu_low" {
  alarm_name          = "${var.prefix}-${var.aws_region}-LowCPU"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "40"

  dimensions {
    ClusterName = "${aws_ecs_cluster.main.name}"
    ServiceName = "${aws_ecs_service.main.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.down.arn}"]
}