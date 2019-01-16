output "cluster_id" {
  description = "The Aurora database cluster ID"
  value       = "${aws_rds_cluster.main.id}"
}

output "cluster_arn" {
  description = "The Aurora database cluster ARN"
  value       = "${aws_rds_cluster.main.arn}"
}

output "cluster_endpoint" {
  description = "The Aurora database cluster writer endpoint"
  value       = "${aws_rds_cluster.main.endpoint}"
}
