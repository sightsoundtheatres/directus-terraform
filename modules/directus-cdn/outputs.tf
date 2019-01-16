output "us-east-1_bucket_name" {
  description = "The us-east-1 bucket name for Directus to use."
  value       = "${aws_s3_bucket.cdn-us-east-1.id}"
}

output "us-west-2_bucket_name" {
  description = "The us-west-2 bucket name for Directus to use."
  value       = "${aws_s3_bucket.cdn-us-west-2.id}"
}
