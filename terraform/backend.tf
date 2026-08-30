resource "aws_s3_bucket" "state-backend" {
  bucket = "multi-env-statebackend-bucket"

  tags = {
    Name = "statebackend"
  }
}
