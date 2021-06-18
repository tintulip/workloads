# Security group for the private db instance
resource "aws_security_group" "web_application_database_sg" {
  name        = "web_application_database_sg"
  description = "For private db instance"
  vpc_id      = module.network.vpc_id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_application_service_sg.id]
  }
}

# Specify particular vpc for the db instance.
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "web-application-db"
  subnet_ids = module.network.private_subnets

  tags = {
    Name = "DB subnet group for the RDS in the workload"
  }
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}


resource "aws_secretsmanager_secret" "db_password" {
  name       = "db_password"
  kms_key_id = aws_kms_key.rds_secret.id
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

resource "aws_kms_key" "rds_secret" {
  description             = "KMS key for the rds password"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}


resource "aws_db_instance" "web_application_db" {
  #checkov:skip=CKV_AWS_161:don't want to have IAM authentication enabled for now

  allocated_storage               = 20
  engine                          = "postgres"
  engine_version                  = "13"
  auto_minor_version_upgrade      = true
  instance_class                  = "db.t3.micro"
  name                            = "web_application_db"
  username                        = "postgres"
  password                        = aws_secretsmanager_secret_version.secret_version.secret_string
  vpc_security_group_ids          = [aws_security_group.web_application_database_sg.id]
  db_subnet_group_name            = aws_db_subnet_group.db_subnet_group.name
  storage_encrypted               = true
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  backup_retention_period         = 7
  monitoring_interval             = 60
  multi_az                        = true
  monitoring_role_arn             = aws_iam_role.rds_enhanced_monitoring.arn
  license_model                   = "postgresql-license"
  identifier                      = "workloads"
  skip_final_snapshot             = true
  final_snapshot_identifier       = "workloads-snapshot"
}

resource "aws_iam_service_linked_role" "rds" {
  aws_service_name = "rds.amazonaws.com"
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  name_prefix        = "rds_enhanced_monitoring-"
  assume_role_policy = data.aws_iam_policy_document.rds_enhanced_monitoring.json
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

data "aws_iam_policy_document" "rds_enhanced_monitoring" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}