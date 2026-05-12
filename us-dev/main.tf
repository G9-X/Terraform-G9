module "networking" {
  source = "../module/Networking"

  project_name              = var.project_name
  environment               = var.environment
  vpc_cidr                  = var.vpc_cidr
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_app_subnet_cidrs  = var.private_app_subnet_cidrs
  private_data_subnet_cidrs = var.private_data_subnet_cidrs
  availability_zones        = var.availability_zones
}

module "security" {
  source = "../module/Security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  backend_port = var.backend_port
}

module "alb" {
  source = "../module/ALB"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  backend_port          = var.backend_port
  health_check_path     = var.health_check_path
}

module "ecr" {
  source = "../module/ECR"

  project_name     = var.project_name
  environment      = var.environment
  image_keep_count = var.ecr_image_keep_count
}

module "database_mysql" {
  count  = var.enable_rds ? 1 : 0
  source = "../module/Database_MySQL"

  project_name             = var.project_name
  environment              = var.environment
  private_data_subnet_ids  = module.networking.private_data_subnet_ids
  rds_security_group_id    = module.security.rds_security_group_id
  db_instance_class        = var.db_instance_class
  db_allocated_storage     = var.db_allocated_storage
  db_max_allocated_storage = var.db_max_allocated_storage
  db_engine                = var.db_engine
  db_engine_version        = var.db_engine_version
  multi_az                 = var.db_multi_az
  db_name                  = var.db_name
  db_username              = var.db_username
  db_password              = var.db_password
}

module "ecs_backend" {
  source = "../module/ECS_Backend"

  project_name              = var.project_name
  environment               = var.environment
  aws_region                = var.aws_region
  private_app_subnet_ids    = module.networking.private_app_subnet_ids
  backend_security_group_id = module.security.backend_security_group_id
  target_group_arn          = module.alb.target_group_arn
  ecr_repository_url        = module.ecr.repository_url
  image_tag                 = var.backend_image_tag
  container_port            = var.backend_port
  cpu                       = var.backend_cpu
  memory                    = var.backend_memory
  desired_count             = var.backend_desired_count
  ec2_instance_type         = var.ecs_instance_type
  ec2_min_size              = var.ecs_ec2_min_size
  ec2_max_size              = var.ecs_ec2_max_size
  ec2_desired_capacity      = var.ecs_ec2_desired_capacity
  db_endpoint               = var.enable_rds ? module.database_mysql[0].db_endpoint : "127.0.0.1"
  db_port                   = 3306
  db_name                   = var.db_name
  db_user                   = var.db_username
  db_password               = var.db_password
  jwt_secret_key            = var.jwt_secret_key
  cloudinary_cloud_name     = var.cloudinary_cloud_name
  cloudinary_api_key        = var.cloudinary_api_key
  cloudinary_api_secret     = var.cloudinary_api_secret
  stripe_secret_key         = var.stripe_secret_key
  stripe_publishable_key    = var.stripe_publishable_key
  stripe_webhook_secret     = var.stripe_webhook_secret
}

module "github_actions_oidc" {
  count  = var.enable_github_actions_oidc ? 1 : 0
  source = "../module/GitHubActionsOIDC"

  project_name                = var.project_name
  environment                 = var.environment
  aws_region                  = var.aws_region
  create_oidc_provider        = var.create_github_oidc_provider
  existing_oidc_provider_arn  = var.existing_github_oidc_provider_arn
  role_name                   = var.github_actions_role_name
  github_repo_owner           = var.github_repo_owner
  github_repo_name            = var.github_repo_name
  github_branch               = var.github_branch
  ecr_repository_name         = module.ecr.repository_name
  ecs_cluster_name            = module.ecs_backend.cluster_name
  ecs_service_name            = module.ecs_backend.service_name
  ecs_task_family             = module.ecs_backend.task_family
  ecs_task_execution_role_arn = module.ecs_backend.task_execution_role_arn
  ecs_task_role_arn           = module.ecs_backend.task_role_arn
}

data "aws_caller_identity" "current" {}

# ═══════════════════════════════════════
# GeekBrain AI Modules
# ═══════════════════════════════════════

module "geekbrain_ai_engine" {
  count  = var.enable_geekbrain ? 1 : 0
  source = "../module/GeekBrain_AI_Engine"

  project            = var.project_name
  name_suffix        = var.environment
  region             = var.aws_region
  account_id         = data.aws_caller_identity.current.account_id
  embedding_model_id = var.geekbrain_embedding_model_id
  kb_docs_path       = var.geekbrain_kb_docs_path

  tags = {
    Environment = var.environment
    Component   = "AIEngine"
  }
}

module "geekbrain_monitoring" {
  count  = var.enable_geekbrain ? 1 : 0
  source = "../module/GeekBrain_Monitoring"

  project         = var.project_name
  vpc_endpoint_id = module.networking.vpc_endpoint_id

  tags = {
    Environment = var.environment
    Component   = "Monitoring"
  }
}

module "geekbrain_backend" {
  count  = var.enable_geekbrain ? 1 : 0
  source = "../module/GeekBrain_Backend"

  project            = var.project_name
  region             = var.aws_region
  account_id         = data.aws_caller_identity.current.account_id
  llm_model_id       = var.geekbrain_llm_model_id
  knowledge_base_id  = module.geekbrain_ai_engine[0].knowledge_base_id
  monitoring_api_url = module.geekbrain_monitoring[0].api_url
  retrieval_k        = var.geekbrain_retrieval_k

  private_subnet_ids = module.networking.private_app_subnet_ids
  lambda_sg_id       = module.security.lambda_security_group_id

  tags = {
    Environment = var.environment
    Component   = "Backend"
  }
}
