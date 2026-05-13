variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.50.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.50.1.0/24", "10.50.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  type    = list(string)
  default = ["10.50.11.0/24", "10.50.12.0/24"]
}

variable "private_data_subnet_cidrs" {
  type    = list(string)
  default = ["10.50.21.0/24", "10.50.22.0/24"]
}

variable "availability_zones" {
  type = list(string)
}

