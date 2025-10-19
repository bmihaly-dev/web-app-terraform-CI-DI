terraform {
  backend "s3" {
    bucket         = "tf-state-terraform-cicd-154744860201-eu-central-1"
    key            = "terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "tf-lock-web-app-tfcicd"
    encrypt        = true
  }
}