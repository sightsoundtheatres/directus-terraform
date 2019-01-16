output "web_sg_id" {
  description = "The ID of the security group used by this web server."
  value       = "${aws_security_group.main.id}"
}
