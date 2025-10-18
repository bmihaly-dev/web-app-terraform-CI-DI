# GitHub OIDC provider (ha még nincs a fiókodban, ez létrehozza)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

# IAM Role, amit a GitHub Actions fel tud venni
resource "aws_iam_role" "gha_tf_role" {
  name = "${var.project_name}-gha-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn },
      Action    = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        },
        StringLike = {
          # ENGEDÉS: bármely ref a konkrét repohoz (main, feature/*, pull_request, stb.)
          "token.actions.githubusercontent.com:sub" : "repo:bmihaly-dev/web-app-terraform-CI-DI:*"
        }
      }
    }]
  })
}

# Policy dokumentum: hozzáférés a backendhez (S3 + DynamoDB lock)
data "aws_iam_policy_document" "gha_backend_only" {
  statement {
    sid = "S3BackendAccess"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.tf_backend_bucket}",
      "arn:aws:s3:::${var.tf_backend_bucket}/${var.tf_backend_key}"
    ]
  }

  statement {
    sid = "DDBLockTable"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem",
      "dynamodb:DescribeTable"
    ]
    resources = [
      "arn:aws:dynamodb:${var.aws_region}:${var.account_id}:table/${var.backend_dynamodb_table}"
    ]
  }
}

resource "aws_iam_policy" "gha_backend_only" {
  name   = "${var.project_name}-gha-backend-only"
  policy = data.aws_iam_policy_document.gha_backend_only.json
}

resource "aws_iam_role_policy_attachment" "attach_backend" {
  role       = aws_iam_role.gha_tf_role.name
  policy_arn = aws_iam_policy.gha_backend_only.arn
}

# Kimenet: ezt kell majd a GitHub Actions-ben beállítani
output "gha_role_arn" {
  value = aws_iam_role.gha_tf_role.arn
}