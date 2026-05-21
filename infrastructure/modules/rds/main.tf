resource "aws_db_instance" "postgres" {
  identifier             = "${var.environment}-backend-db"
  engine                 = "postgres"
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  
  # Database Credentials
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  
  # Network & Security
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = var.vpc_security_group_ids

  # LocalStack / Dev specific settings
  skip_final_snapshot    = true
  publicly_accessible    = true 
  
  tags = var.tags
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.environment}-rds-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}