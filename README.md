

# 🚀 Terraform CI/CD with GitHub OIDC

This project shows how to run **Terraform securely from GitHub Actions** without storing long-lived AWS credentials.  
Authentication is handled via **AWS IAM OpenID Connect (OIDC)** trust with GitHub.

---

## ✅ Requirements

- AWS account with IAM permissions to create:
  - **S3 bucket** (Terraform state)
  - **DynamoDB table** (state locking)
  - **OIDC provider + IAM role** (for GitHub Actions)
- Terraform `>= 1.3`
- GitHub repository (private or public)

---

## 🔹 Step 1 — Backend Setup

Terraform state is stored remotely in AWS.

Create:
- **S3 bucket**:  
  `tf-state-terraform-cicd-<YOUR_ACCOUNT_ID>-eu-central-1`
- **DynamoDB table**:  
  `tf-lock-terraform-cicd` (partition key = `LockID`, type = String)

---

## 🔹 Step 2 — IAM OIDC Role

Terraform configures:
- **OIDC provider**: `https://token.actions.githubusercontent.com`
- **IAM role**: `terraform-cicd-gha-terraform-role`

Trust policy must allow OIDC tokens from your repo:

```json
"Condition": {
  "StringEquals": {
    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
  },
  "StringLike": {
    "token.actions.githubusercontent.com:sub": "repo:<github_owner>/<github_repo>:*"
  }
}

---
## 🔹 Step 3 — Terraform Variables

Edit terraform/terraform.tfvars with your values:

aws_region             = "eu-central-1"
account_id             = "<your-account-id>"
project_name           = "terraform-cicd"

backend_bucket         = "tf-state-terraform-cicd-<account_id>-eu-central-1"
backend_key            = "terraform.tfstate"
backend_dynamodb_table = "tf-lock-terraform-cicd"

github_owner           = "<your-github-username-or-org>"
github_repo            = "<your-repo-name>"

---

## 🔹 Step 4 — GitHub Repository Variables

Go to GitHub → Repo → Settings → Secrets and variables → Actions → Variables, and add:

Name	Value
AWS_ROLE_TO_ASSUME	arn:aws:iam::<account_id>:role/terraform-cicd-gha-terraform-role
TF_BACKEND_BUCKET	tf-state-terraform-cicd-<account_id>-eu-central-1
TF_BACKEND_KEY	terraform.tfstate
TF_BACKEND_DDB	tf-lock-terraform-cicd

---

## 🔹 Step 5 — GitHub Actions Workflow

The workflow is defined in .github/workflows/terraform.yml.






