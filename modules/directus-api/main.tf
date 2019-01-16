# Providers

provider "aws" {
  region = "${var.aws_region}"
}

# Modules

module "vpc" {
  source = "../directus-vpc"

  aws_region = "${var.aws_region}"
  prefix     = "${var.prefix}"
  vpc_cidr   = "${var.vpc_cidr}"
}

module "lb" {
  source = "../directus-lb"

  aws_region    = "${var.aws_region}"
  prefix        = "${var.prefix}"
  vpc_id        = "${module.vpc.vpc_id}"
  r53_zone_id   = "${var.r53_zone_id}"
  r53_subdomain = "${var.r53_subdomain}"
}

module "ecs" {
  source = "../directus-ecs"

  aws_region      = "${var.aws_region}"
  prefix          = "${var.prefix}"
  vpc_id          = "${module.vpc.vpc_id}"
  lb_sg_id        = "${module.lb.lb_sg_id}"
  lb_tg_id        = "${module.lb.lb_tg_id}"
  task_count      = "${var.task_count}"
  docker_image    = "${var.docker_image}"
  s3_bucket_name  = "${var.cdn_bucket_name}"
  s3_user_key     = "${var.s3_user_key}"
  s3_user_secret  = "${var.s3_user_secret}"
  db_endpoint     = "${module.db.cluster_endpoint}"
  db_name         = "${var.db_name}"
  db_username     = "${var.db_username}"
  db_password     = "${var.db_password}"
  cdn_domain_name = "${var.cdn_domain_name}"
}

module "db" {
  source = "../directus-db"

  aws_region         = "${var.aws_region}"
  prefix             = "${var.prefix}"
  vpc_id             = "${module.vpc.vpc_id}"
  web_sg_id          = "${module.ecs.web_sg_id}"
  db_name            = "${var.db_name}"
  db_master_username = "${var.db_username}"
  db_master_password = "${var.db_password}"
  db_instance_count  = "${var.db_count}"

  db_replication_source_cluster_arn = "${var.db_replication_source_cluster_arn}"
}
