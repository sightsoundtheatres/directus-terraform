# Providers

provider "aws" {
  region = "${var.aws_region}"
}

# Data Sources

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "main" {
  id = "${var.vpc_id}"
}

# Subnets

resource "aws_subnet" "main" {
  count = 3

  vpc_id                          = "${data.aws_vpc.main.id}"
  availability_zone               = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block                      = "${cidrsubnet(data.aws_vpc.main.cidr_block, 4, 8 + count.index)}"
  ipv6_cidr_block                 = "${cidrsubnet(data.aws_vpc.main.ipv6_cidr_block, 8, 24 + count.index)}"
  assign_ipv6_address_on_creation = true

  tags {
    Name        = "${var.prefix}-${var.aws_region}-DB${format("%02d", count.index + 1)}"
    Environment = "CMS"
  }
}

# Security Groups

resource "aws_security_group" "main" {
  name   = "${var.prefix}-${var.aws_region}-DB"
  vpc_id = "${data.aws_vpc.main.id}"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${var.web_sg_id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  tags {
    Name        = "${var.prefix}-${var.aws_region}-DB"
    Environment = "CMS"
  }
}

# Database Subnet Groups

resource "aws_db_subnet_group" "main" {
  name       = "${lower(var.prefix)}-${var.aws_region}-sg"
  subnet_ids = ["${aws_subnet.main.*.id}"]

  tags = {
    Environment = "CMS"
  }
}

# RDS Clusters

resource "aws_rds_cluster" "main" {
  cluster_identifier              = "${lower(var.prefix)}-${var.aws_region}-cluster"
  engine                          = "aurora-mysql"
  vpc_security_group_ids          = ["${aws_security_group.main.id}"]
  db_subnet_group_name            = "${aws_db_subnet_group.main.id}"
  db_cluster_parameter_group_name = "${aws_rds_cluster_parameter_group.main.id}"

  database_name   = "${var.db_name}"
  master_username = "${var.db_master_username}"
  master_password = "${var.db_master_password}"

  replication_source_identifier = "${var.db_replication_source_cluster_arn}"

  backup_retention_period = 7
  preferred_backup_window = "07:00-07:30"

  deletion_protection = true
  apply_immediately   = true
  skip_final_snapshot = true

  tags {
    Environment = "CMS"
  }
}

# RDS Cluster Parameter Groups

resource "aws_rds_cluster_parameter_group" "main" {
  name   = "${lower(var.prefix)}-${var.aws_region}-cluster-pg"
  family = "aurora-mysql5.7"

  parameter {
    name         = "binlog_format"
    value        = "MIXED"
    apply_method = "pending-reboot"
  }

  tags {
    Environment = "CMS"
  }
}

# RDS Cluster Instances

resource "aws_rds_cluster_instance" "main" {
  count               = "${var.db_instance_count}"
  engine              = "aurora-mysql"
  identifier          = "${lower(var.prefix)}-${var.aws_region}-${format("%02d", count.index + 1)}"
  cluster_identifier  = "${aws_rds_cluster.main.id}"
  instance_class      = "db.t3.small"
  monitoring_interval = "60"

  tags {
    Environment = "CMS"
  }
}
