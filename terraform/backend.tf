terraform {
  backend "s3" {
    bucket       = "secure-eks-gitops-terraform-state-dishen"
    key          = "eks/platform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
  }
}
