variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_app_subnet_ids" {
  type = list(string)
}

variable "backend_security_group_id" {
  description = "SG of the ECS Backend tasks (to allow NFS ingress)"
  type        = string
}
