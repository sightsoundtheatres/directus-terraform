output "vpc_id" {
  description = "The ID of the created VPC"
  value       = "${aws_vpc.main.id}"
}
