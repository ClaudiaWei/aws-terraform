resource "aws_ecr_repository" "project_api" {
  name                 = "project_api"
  image_tag_mutability = "MUTABLE"
  encryption_configuration {
    encryption_type = "AES256"
  }
  image_scanning_configuration {
    scan_on_push = "false"
  }
}
