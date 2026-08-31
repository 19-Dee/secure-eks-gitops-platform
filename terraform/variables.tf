variable "availability_zones" {
  type    = list(string)
  default = ["eu-west-2a", "eu-west-2b"]
}

variable "aws_region" {
  type    = string
  default = "eu-west-2"
}
