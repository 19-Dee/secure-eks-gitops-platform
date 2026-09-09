resource "aws_ecr_repository" "aws_multienv_ecr_repo" {
  name                 = "multienv-app"
  force_delete         = true
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
