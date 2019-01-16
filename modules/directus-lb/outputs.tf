output "lb_sg_id" {
  description = "The ID of the security group used by this load balancer."
  value       = "${aws_security_group.main.id}"
}

output "lb_tg_id" {
  description = "The ID of the target group used by this load balancer."
  value       = "${aws_lb_target_group.main.id}"
}
