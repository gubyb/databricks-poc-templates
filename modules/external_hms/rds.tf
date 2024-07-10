# Not a prod ready deploy!
resource "aws_db_instance" "default" {
  identifier        = "${var.prefix}-rds-instance"
  allocated_storage = 50
  storage_type      = "gp3"
  db_name           = "hive"
  engine            = "mysql"
  engine_version    = "8.0.35"
  instance_class    = "db.m6gd.large"
  username          = "admin"
  password          = "gustavadmin"
  port              = 3306
  multi_az          = false

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name

  skip_final_snapshot = false
  final_snapshot_identifier = "finalsnap"

  tags = merge(var.tags, {
    Name = "${var.prefix}-rds-instance"
  })

  deletion_protection = false

  tags_all = var.tags
}
