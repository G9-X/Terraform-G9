variable "project" { type = string }
variable "tags" { type = map(string) }
variable "vpc_endpoint_id" {
  description = "VPC Interface Endpoint ID for API Gateway private access"
  type        = string
}
