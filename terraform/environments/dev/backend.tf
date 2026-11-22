terraform {
  backend "s3" {
    bucket       = "state-file-terraform-036253061913"
    key          = "/dev/terraform.tfstate"
    region       = "eu-west-1"
    profile      = "new-user"
    use_lockfile = true
  }
}