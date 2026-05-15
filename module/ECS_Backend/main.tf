resource "aws_ecs_cluster" "backend" {
  name = "${var.project_name}-backend-${var.environment}"
}

data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}/backend/${var.environment}"
  retention_in_days = 14
}

locals {
  backend_db_connection_string = "Server=${var.db_endpoint};Port=${var.db_port};Database=${var.db_name};User=${var.db_user};Password=${var.db_password};SslMode=Preferred;"
}

resource "aws_secretsmanager_secret" "backend_db_connection" {
  name                    = "${var.project_name}/backend/${var.environment}/db-connection"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "backend_db_connection" {
  secret_id     = aws_secretsmanager_secret.backend_db_connection.id
  secret_string = local.backend_db_connection_string
}

resource "aws_secretsmanager_secret" "backend_jwt_secret_key" {
  name                    = "${var.project_name}/backend/${var.environment}/jwt-secret-key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "backend_jwt_secret_key" {
  secret_id     = aws_secretsmanager_secret.backend_jwt_secret_key.id
  secret_string = var.jwt_secret_key
}

resource "aws_secretsmanager_secret" "backend_cloudinary_cloud_name" {
  name                    = "${var.project_name}/backend/${var.environment}/cloudinary-cloud-name"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "backend_cloudinary_cloud_name" {
  secret_id     = aws_secretsmanager_secret.backend_cloudinary_cloud_name.id
  secret_string = var.cloudinary_cloud_name
}

resource "aws_secretsmanager_secret" "backend_cloudinary_api_key" {
  name                    = "${var.project_name}/backend/${var.environment}/cloudinary-api-key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "backend_cloudinary_api_key" {
  secret_id     = aws_secretsmanager_secret.backend_cloudinary_api_key.id
  secret_string = var.cloudinary_api_key
}

resource "aws_secretsmanager_secret" "backend_cloudinary_api_secret" {
  name                    = "${var.project_name}/backend/${var.environment}/cloudinary-api-secret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "backend_cloudinary_api_secret" {
  secret_id     = aws_secretsmanager_secret.backend_cloudinary_api_secret.id
  secret_string = var.cloudinary_api_secret
}

resource "aws_secretsmanager_secret" "backend_stripe_secret_key" {
  name                    = "${var.project_name}/backend/${var.environment}/stripe-secret-key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "backend_stripe_secret_key" {
  secret_id     = aws_secretsmanager_secret.backend_stripe_secret_key.id
  secret_string = var.stripe_secret_key
}

resource "aws_secretsmanager_secret" "backend_stripe_publishable_key" {
  name                    = "${var.project_name}/backend/${var.environment}/stripe-publishable-key"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "backend_stripe_publishable_key" {
  secret_id     = aws_secretsmanager_secret.backend_stripe_publishable_key.id
  secret_string = var.stripe_publishable_key
}

resource "aws_secretsmanager_secret" "backend_stripe_webhook_secret" {
  name                    = "${var.project_name}/backend/${var.environment}/stripe-webhook-secret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "backend_stripe_webhook_secret" {
  secret_id     = aws_secretsmanager_secret.backend_stripe_webhook_secret.id
  secret_string = var.stripe_webhook_secret
}

data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution_role" {
  name               = "${var.project_name}-ecs-exec-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "execution_secret_access" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      aws_secretsmanager_secret.backend_db_connection.arn,
      aws_secretsmanager_secret.backend_jwt_secret_key.arn,
      aws_secretsmanager_secret.backend_cloudinary_cloud_name.arn,
      aws_secretsmanager_secret.backend_cloudinary_api_key.arn,
      aws_secretsmanager_secret.backend_cloudinary_api_secret.arn,
      aws_secretsmanager_secret.backend_stripe_secret_key.arn,
      aws_secretsmanager_secret.backend_stripe_publishable_key.arn,
      aws_secretsmanager_secret.backend_stripe_webhook_secret.arn
    ]
  }
}

resource "aws_iam_role_policy" "execution_secret_access" {
  name   = "${var.project_name}-ecs-exec-secret-${var.environment}"
  role   = aws_iam_role.execution_role.id
  policy = data.aws_iam_policy_document.execution_secret_access.json
}

resource "aws_iam_role" "task_role" {
  name               = "${var.project_name}-ecs-task-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

data "aws_iam_policy_document" "task_ssm_exec" {
  statement {
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "task_ssm_exec" {
  name   = "${var.project_name}-ecs-task-ssm-${var.environment}"
  role   = aws_iam_role.task_role.id
  policy = data.aws_iam_policy_document.task_ssm_exec.json
}

# --- EFS Access Policy for Task Role (Week 5) ---
data "aws_iam_policy_document" "task_efs_access" {
  count = var.efs_file_system_arn != "" ? 1 : 0

  statement {
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientRootAccess"
    ]
    resources = [var.efs_file_system_arn]
  }
}

resource "aws_iam_role_policy" "task_efs_access" {
  count  = var.efs_file_system_arn != "" ? 1 : 0
  name   = "${var.project_name}-ecs-task-efs-${var.environment}"
  role   = aws_iam_role.task_role.id
  policy = data.aws_iam_policy_document.task_efs_access[0].json
}

data "aws_iam_policy_document" "ecs_instance_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name               = "${var.project_name}-ecs-instance-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ecs_instance_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ec2" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ssm" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ecs_instance" {
  name = "${var.project_name}-ecs-instance-profile-${var.environment}"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.project_name}-ecs-${var.environment}-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = var.ec2_instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_instance.arn
  }

  vpc_security_group_ids = [var.backend_security_group_id]

  user_data = base64encode(<<-EOT
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.backend.name} >> /etc/ecs/ecs.config
    echo ECS_ENABLE_CONTAINER_METADATA=true >> /etc/ecs/ecs.config
  EOT
  )

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

resource "aws_autoscaling_group" "ecs" {
  name                = "${var.project_name}-ecs-asg-${var.environment}"
  min_size            = var.ec2_min_size
  max_size            = var.ec2_max_size
  desired_capacity    = var.ec2_desired_capacity
  vpc_zone_identifier = var.private_app_subnet_ids
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-ecs-${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "ec2" {
  name = "${var.project_name}-cp-${var.environment}"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs.arn

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100
    }

    managed_termination_protection = "DISABLED"
  }
}

resource "aws_ecs_cluster_capacity_providers" "backend" {
  cluster_name = aws_ecs_cluster.backend.name

  capacity_providers = [aws_ecs_capacity_provider.ec2.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 1
    base              = 1
  }
}

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend-${var.environment}"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn

  # --- EFS Volume (Week 5 Hardening) ---
  dynamic "volume" {
    for_each = var.efs_file_system_id != "" ? [1] : []

    content {
      name = "efs-storage"

      efs_volume_configuration {
        file_system_id          = var.efs_file_system_id
        transit_encryption      = "ENABLED"
        authorization_config {
          access_point_id = var.efs_access_point_id
          iam             = "ENABLED"
        }
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      mountPoints = var.efs_file_system_id != "" ? [
        {
          sourceVolume  = "efs-storage"
          containerPath = "/mnt/efs"
          readOnly      = false
        }
      ] : []
      environment = [
        {
          name  = "ASPNETCORE_URLS"
          value = "http://+:${var.container_port}"
        },
        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = var.environment
        }
      ]
      secrets = [
        {
          name      = "ConnectionStrings__DefaultConnection"
          valueFrom = aws_secretsmanager_secret.backend_db_connection.arn
        },
        {
          name      = "JWT__SecretKey"
          valueFrom = aws_secretsmanager_secret.backend_jwt_secret_key.arn
        },
        {
          name      = "CloudinarySettings__CloudName"
          valueFrom = aws_secretsmanager_secret.backend_cloudinary_cloud_name.arn
        },
        {
          name      = "CloudinarySettings__ApiKey"
          valueFrom = aws_secretsmanager_secret.backend_cloudinary_api_key.arn
        },
        {
          name      = "CloudinarySettings__ApiSecret"
          valueFrom = aws_secretsmanager_secret.backend_cloudinary_api_secret.arn
        },
        {
          name      = "StripeSettings__SecretKey"
          valueFrom = aws_secretsmanager_secret.backend_stripe_secret_key.arn
        },
        {
          name      = "StripeSettings__PublishableKey"
          valueFrom = aws_secretsmanager_secret.backend_stripe_publishable_key.arn
        },
        {
          name      = "StripeSettings__WebhookSecret"
          valueFrom = aws_secretsmanager_secret.backend_stripe_webhook_secret.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.backend.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend-svc-${var.environment}"
  cluster         = aws_ecs_cluster.backend.id
  task_definition        = aws_ecs_task_definition.backend.arn
  desired_count          = var.desired_count
  enable_execute_command = true

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 1
    base              = 1
  }

  network_configuration {
    subnets          = var.private_app_subnet_ids
    security_groups  = [var.backend_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "backend"
    container_port   = var.container_port
  }

  depends_on = [
    aws_iam_role_policy_attachment.execution_managed,
    aws_iam_role_policy.execution_secret_access,
    aws_ecs_cluster_capacity_providers.backend
  ]
}
