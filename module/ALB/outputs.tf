output "target_group_arn" {
  value = aws_lb_target_group.backend.arn
}

output "alb_dns_name" {
  value = aws_lb.backend.dns_name
}

output "listener_arn" {
  value = aws_lb_listener.http.arn
}
