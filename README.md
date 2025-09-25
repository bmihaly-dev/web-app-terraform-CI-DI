
# 🚀 Terraform CI/CD with GitHub OIDC

This project shows how to run **Terraform securely from GitHub Actions** without storing long-lived AWS credentials.  
Authentication is handled via **AWS IAM OpenID Connect (OIDC)** trust with GitHub.  
Remote Terraform state is stored in **S3**, locking in **DynamoDB**.

---

## 📂 Project Structure

```
terraform-CICD/
├── terraform/                  # Terraform configuration
│   ├── backend.tf              # Remote backend (S3 + DynamoDB)
│   ├── iam-oidc.tf             # IAM role + OIDC provider
│   ├── variables.tf            # Variable definitions
│   ├── terraform.tfvars        # Your account/repo-specific values
│   └── ...
└── .github/workflows/
    └── terraform.yml           # GitHub Actions workflow
```

---

## ✅ Requirements

- AWS account with permissions to create:
  - **S3 bucket** (Terraform state)
  - **DynamoDB table** (state locking)
  - **OIDC provider + IAM role** (for GitHub Actions)
- Terraform `>= 1.3`
- GitHub repository (private or public)

---

## ⚡ Quickstart Bootstrap (one-time)

Create the backend **once** with AWS CLI (replace `<YOUR_ACCOUNT_ID>`):

```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket tf-state-terraform-cicd-<YOUR_ACCOUNT_ID>-eu-central-1 \
  --region eu-central-1 \
  --create-bucket-configuration LocationConstraint=eu-central-1

# Enable versioning (recommended)
aws s3api put-bucket-versioning \
  --bucket tf-state-terraform-cicd-<YOUR_ACCOUNT_ID>-eu-central-1 \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name tf-lock-terraform-cicd \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-central-1
```

## 🔹 Step 1 — Terraform Variables

Edit `terraform/terraform.tfvars` with your values:

```hcl
aws_region             = "eu-central-1"
account_id             = "<your-account-id>"
project_name           = "terraform-cicd"

backend_bucket         = "tf-state-terraform-cicd-<account_id>-eu-central-1"
backend_key            = "terraform.tfstate"
backend_dynamodb_table = "tf-lock-terraform-cicd"

github_owner           = "<your-github-username-or-org>"
github_repo            = "<your-repo-name>"
```

> Ensure `github_owner` / `github_repo` **exactly** match your GitHub repo (case-sensitive).

---

## 🔹 Step 2 — GitHub Repository Variables

In **GitHub → Repo → Settings → Secrets and variables → Actions → Variables**, add:

| Name               | Value                                                                 |
|--------------------|-----------------------------------------------------------------------|
| `AWS_ROLE_TO_ASSUME` | `arn:aws:iam::<account_id>:role/terraform-cicd-gha-terraform-role` |
| `TF_BACKEND_BUCKET`  | `tf-state-terraform-cicd-<account_id>-eu-central-1`                |
| `TF_BACKEND_KEY`     | `terraform.tfstate`                                                |
| `TF_BACKEND_DDB`     | `tf-lock-terraform-cicd`                                           |

Set `AWS_REGION` in the workflow (already set to `eu-central-1` in this repo).

---
## 🐳 Step 3 — Docker Build & Push to ECR

This project assumes your application is containerized and stored in **AWS Elastic Container Registry (ECR)**.

### 1. Create an ECR Repository (one time)

Create a dockerfile for your web application.

### 3. Authenticate Docker to ECR

```bash
aws ecr get-login-password --region eu-central-1 \
  | docker login --username AWS --password-stdin <YOUR_ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com
```

### 5. Push Image to ECR

## ▶️ Usage

- Open PR → **Plan** runs automatically (artifact: `plan.out`)
- Merge to `main` → **Apply** runs automatically
- Local runs (optional) always use the same remote backend

---

## 🔒 Security Notes

- Scope the trust policy to your **exact** repo:
  ```
  repo:<github_owner>/<github_repo>:*
  ```
  Avoid `repo:<owner>/*` unless all repos under the owner should have access.
- OIDC thumbprints required:
  - `6938fd4d98bab03faadb97b34396831e3780aea1`
  - `1c58a3a8518e8759bf075b76b750d4f2df264fcd`
- Never commit `backend.hcl`, state files, or `.terraform/`.

---

## ✅ Done

With this setup:
- **No AWS keys** in GitHub
- GitHub Actions authenticates via **OIDC**
- Terraform state in **S3**, locking in **DynamoDB**
- Automated flow: **Plan on PR**, **Apply on main**







