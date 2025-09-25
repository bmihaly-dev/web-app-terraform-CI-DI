terraform {
  backend "s3" {
    bucket         = "tf-state-terraform-cicd-<ACCOUNT_ID>-eu-central-1"
    key            = "state/app.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "tf-lock-terraform-cicd"
    encrypt        = true
  }
}