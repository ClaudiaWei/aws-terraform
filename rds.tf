data "aws_secretsmanager_secret" "project_secret" {
  name = "project_postgres_password"
}

data "aws_secretsmanager_secret_version" "project_secret_version"{
  secret_id = data.aws_secretsmanager_secret.project_secret.id
}

resource "aws_db_instance" "project_postgres" {
  allocated_storage                     = "20"
  availability_zone                     = "${var.region}a"
  backup_retention_period               = "7"
  copy_tags_to_snapshot                 = "true"
  customer_owned_ip_enabled             = "false"
  db_name                               = var.db_name
  db_subnet_group_name                  = aws_db_subnet_group.project_db_subnet_group.name
  enabled_cloudwatch_logs_exports       = ["postgresql"]
  engine                                = "postgres"
  engine_version                        = var.engine_version
  iam_database_authentication_enabled   = "false"
  identifier                            = var.identifier
  instance_class                        = var.instance_class
  max_allocated_storage                 = "1000"
  multi_az                              = "false"
  parameter_group_name                  = "project-db-parameter-group"
  performance_insights_enabled          = "true"
  performance_insights_retention_period = "7"
  port                                  = "5432"
  publicly_accessible                   = "false"
  storage_encrypted                     = "true"
  storage_type                          = "gp2"
  username                              = var.username
  password                              = data.aws_secretsmanager_secret_version.project_secret_version.secret_string
  vpc_security_group_ids                = [aws_security_group.project_rds.id]
  skip_final_snapshot                   = true
  tags = {
    Terraform   = "true"
  }
}

resource "aws_db_parameter_group" "project_db_parameter_group" {
  name        = "project-db-parameter-group"
  description = "project_db_parameter_group"
  family      = var.family
}

resource "aws_db_subnet_group" "project_db_subnet_group" {
  name        = "project_db_subnet_group"
  description = "project_db_subnet_group"
  subnet_ids  = [aws_subnet.project_private_subnet_1a.id, aws_subnet.project_private_subnet_1c.id]
}