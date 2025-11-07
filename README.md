🚀 Terraform CI/CD with GitHub OIDC

This project demonstrates how to run Terraform securely from GitHub Actions without storing long-lived AWS credentials.
Authentication is handled via AWS IAM OpenID Connect (OIDC) trust with GitHub.
Terraform remote state is stored in S3, and state locking is managed via DynamoDB.

📚 Table of Contents

About The Project

Project Structure

Requirements

Getting Started

Step 0 — Bootstrap the Backend

Step 1 — Configure Terraform Variables

Step 2 — GitHub Repository Variables

Step 3 — Build & Push Your Docker Image

CI/CD Flow

Security Notes

Summary

License

Acknowledgments

📖 About The Project

This setup provides a fully automated Terraform deployment pipeline that authenticates to AWS securely via GitHub OIDC — eliminating the need for static AWS credentials.

Region: eu-central-1 (Frankfurt)
State bucket: tf-state-terraform-cicd-<ACCOUNT_ID>-eu-central-1
Lock table: tf-lock-terraform-cicd
GitHub OIDC role: terraform-cicd-gha-terraform-role
ECR repo example: reactflow
App Runner service: reactflow-prod (auto-deploy enabled for the latest image tag)

📂 Project Structure
terraform-CICD/
├── terraform-bootstrap/        # Step 0: bootstrap backend (S3 + DynamoDB)
│   └── main.tf                 # Creates state bucket and lock table
├── terraform/                  # Main Terraform configuration
│   ├── backend.tf              # Remote backend config (S3 + DynamoDB)
│   ├── iam-oidc.tf             # GitHub OIDC provider + IAM roles
│   ├── ecr_apprunner.tf        # ECR repository + App Runner service
│   ├── variables.tf            # Variable definitions
│   ├── terraform.tfvars        # Your account/repo-specific values
│   └── outputs.tf              # Example: App Runner public URL
└── .github/
    └── workflows/
        └── terraform.yml       # GitHub Actions workflow (OIDC + Terraform)

✅ Requirements

AWS account with permissions to create S3, DynamoDB, IAM, ECR, and App Runner resources

Terraform ≥ 1.3

GitHub repository (private or public)

GitHub Actions with OIDC trust enabled (configured by this code)

⚡ Getting Started
Step 0 — Bootstrap the Backend

Before running the main Terraform configuration, create the backend resources using the terraform-bootstrap/ directory.
This replaces the old manual AWS CLI setup.

cd terraform-bootstrap
terraform init
terraform plan
terraform apply


This step creates:

S3 bucket: tf-state-terraform-cicd-<ACCOUNT_ID>-eu-central-1

DynamoDB table: tf-lock-terraform-cicd

💡 It’s recommended to add
prevent_destroy = true
to the bucket lifecycle block to avoid accidental deletion.

Step 1 — Configure Terraform Variables

Edit terraform/terraform.tfvars and set your values:

aws_region     = "eu-central-1"
account_id     = "<your-account-id>"
project        = "terraform-cicd"

github_owner   = "<your-github-username>"
github_repo    = "<your-repo-name>"

ecr_repository = "reactflow"


Ensure github_owner and github_repo exactly match your GitHub repository (case-sensitive).

Step 2 — GitHub Repository Variables

In your GitHub repository go to:
Settings → Secrets and variables → Actions → Variables
and add the following:

Name	Value
AWS_ROLE_TO_ASSUME	arn:aws:iam::<ACCOUNT_ID>:role/terraform-cicd-gha-terraform-role
TF_BACKEND_BUCKET	tf-state-terraform-cicd-<ACCOUNT_ID>-eu-central-1
TF_BACKEND_KEY	terraform.tfstate
TF_BACKEND_DDB	tf-lock-terraform-cicd

AWS_REGION is already defined in the workflow as eu-central-1.

Step 3 — Build & Push Your Docker Image

This project assumes your application is containerized and stored in AWS Elastic Container Registry (ECR).
The Terraform code automatically creates the ECR repository.

GitHub Actions will:

Build your Docker image

Authenticate via OIDC

Push the image to ECR

Trigger App Runner auto-deploy (if auto_deployments_enabled = true)

▶️ CI/CD Flow
Action	Trigger	Description
Pull Request	terraform plan	Runs automatically, uploads plan artifact
Merge to main	terraform apply	Applies changes to AWS
Image Push to ECR	auto deploy	App Runner detects new image and redeploys
Manual run	workflow_dispatch	Optional local or manual execution
🔒 Security Notes

IAM trust policy is scoped strictly to your repository:
repo:<github_owner>/<github_repo>:*

OIDC thumbprints required (already configured):

6938fd4d98bab03faadb97b34396831e3780aea1
1b511abead59c6ce207077c0bf0e0043b1382612


Never commit:

.terraform/
terraform.tfstate
backend credentials or backend.hcl

✅ Summary

With this setup:

✅ No AWS keys are stored in GitHub
🔐 OIDC securely authenticates GitHub Actions to AWS
📦 Terraform state stored remotely in S3
🔒 State locking handled by DynamoDB
⚙️ Fully automated pipeline: plan on PR → apply on main
🚀 App Runner auto-deploys whenever a new Docker image is pushed to ECR