module "network" {
  source      = "../../components/networking"
  owner       = "platform"
  account_id  = data.aws_caller_identity.preproduction.account_id
  environment = local.environment
}

# Security group for the private db instance
resource "aws_security_group" "web_application_database_sg" {
  name        = "web_application_database_sg"
  description = "For private db instance"
  vpc_id      = module.network.vpc_id
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Specify particular vpc for the db instance.
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "web-application"
  subnet_ids = [module.network.private_subnets.id]

  tags = {
    Name = "DB subnet group for the RDS workloads"
  }
}

resource "aws_db_instance" "web_application" {
  allocated_storage = 10
  engine            = "mysql"
  engine_version    = "5.7"
  instance_class    = "db.t3.micro"
  name              = "workloads-db"
  #   username             = "foo"
  #   password             = "foobarbaz"
  parameter_group_name   = "default.mysql5.7"
  skip_final_snapshot    = true
  vpc_security_group_ids = aws_security_group.web_application_database_sg.id
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group
}