terraform {
  backend "local" {
    
  }
}
/*
bucket         = "tf-state-terraform-cicd-demo"
    key            = "state/app.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "tf-lock-terraform-cicd"
    encrypt        = true */