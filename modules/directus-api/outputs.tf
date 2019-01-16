output "db_cluster_arn" {
  description = "The ARN of the Aurora cluster."
  value       = "${module.db.cluster_arn}"
}
