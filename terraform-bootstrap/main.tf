provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

############################
# Locals – egységes névképzés
############################
locals {
  bucket_name = "tf-state-${var.project}-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  lock_table  = "tf-lock-${var.project}"
}

############################
# S3 backend bucket + kiegészítők
############################
resource "aws_s3_bucket" "tf_state" {
  bucket        = local.bucket_name
  force_destroy = true
  tags = {
    Project = var.project
    Purpose = "terraform-state"
  }
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_dynamodb_table" "tf_lock" {
  name         = local.lock_table
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Project = var.project
    Purpose = "terraform-lock"
  }
}


resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
 
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1b511abead59c6ce207077c0bf0e0043b1382612"
  ]
}


locals {
  gha_trust_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn },
      Action    = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" },
        StringLike   = { "token.actions.githubusercontent.com:sub" = "repo:${var.gh_owner}/${var.gh_repo}:*" }
      }
    }]
  })
}


resource "aws_iam_role" "gha_ecr_push" {
  name               = "reactflow-gha-ecr-push"
  assume_role_policy = local.gha_trust_policy
}

resource "aws_iam_role_policy" "gha_ecr_push_inline" {
  role = aws_iam_role.gha_ecr_push.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "ecr:GetAuthorizationToken",
        "ecr:DescribeRepositories","ecr:DescribeImages",
        "ecr:BatchCheckLayerAvailability","ecr:BatchGetImage","ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload","ecr:UploadLayerPart","ecr:CompleteLayerUpload","ecr:PutImage",
        "sts:GetCallerIdentity"
      ],
      Resource = "*"
    }]
  })
}


# Role a Terraform workflow-hoz (backend + App Runner + ECR read)

resource "aws_iam_role" "gha_terraform" {
  name               = "terraform-cicd-gha-terraform-role"
  assume_role_policy = local.gha_trust_policy
}

resource "aws_iam_role_policy" "gha_terraform_inline" {
  role = aws_iam_role.gha_terraform.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
     
      {
        Effect   = "Allow",
        Action   = ["s3:ListBucket","s3:GetBucketLocation"],
        Resource = "arn:aws:s3:::${local.bucket_name}"
      },
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject","s3:PutObject","s3:DeleteObject",
          "s3:GetObjectVersion","s3:DeleteObjectVersion","s3:PutObjectAcl"
        ],
        Resource = "arn:aws:s3:::${local.bucket_name}/*"
      },

      
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:DescribeTable","dynamodb:GetItem","dynamodb:PutItem",
          "dynamodb:DeleteItem","dynamodb:UpdateItem"
        ],
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${local.lock_table}"
      },

      # --- ECR: olvasás + lifecycle policy + auth token ---
      {
        Sid      = "EcrReadForPlan",
        Effect   = "Allow",
        Action   = [
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:ListImages",
          "ecr:ListTagsForResource",
          "ecr:GetLifecyclePolicy"         # <-- új
        ],
        Resource = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repository}"
      },
     
      {
        Sid      = "EcrLifecycleCrudIfManaged",
        Effect   = "Allow",
        Action   = [
          "ecr:PutLifecyclePolicy",
          "ecr:DeleteLifecyclePolicy"
        ],
        Resource = "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repository}"
      },
      {
        Sid      = "EcrAuthToken",
        Effect   = "Allow",
        Action   = "ecr:GetAuthorizationToken",
        Resource = "*"
      },

      
      {
        Sid      = "AppRunnerRead",
        Effect   = "Allow",
        Action   = [
          "apprunner:DescribeService",
          "apprunner:ListServices",
          "apprunner:ListTagsForResource"   # <-- úja
        ],
        Resource = "arn:aws:apprunner:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/*"
      },

      # --- IAM: szerepek olvasása + inline policy listázás ---
      {
        Sid      = "IamReadAppRunnerRoles",
        Effect   = "Allow",
        Action   = [
          "iam:GetRole",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:GetRolePolicy"
        ],
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AppRunnerECRAccessRole",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/apprunner-access-prod"
        ]
      },

      # --- Alap ---
      { "Effect":"Allow","Action":["sts:GetCallerIdentity"],"Resource":"*" }
    ]
  })
}

############################
# ECR repository az alkalmazáshoz
############################
resource "aws_ecr_repository" "app" {
  name = var.ecr_repository
  image_scanning_configuration { scan_on_push = true }
  force_delete = true  
  tags = { Project = var.project }
}

############################
# App Runner ECR access role
############################
resource "aws_iam_role" "apprunner_ecr_access" {
  name = "AppRunnerECRAccessRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "apprunner.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "apprunner_ecr_access_inline" {
  role = aws_iam_role.apprunner_ecr_access.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage","ecr:GetDownloadUrlForLayer","ecr:BatchCheckLayerAvailability",
        "logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"
      ],
      Resource = "*"
    }]
  })
}