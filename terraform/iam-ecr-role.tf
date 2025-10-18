resource "aws_iam_role" "reactflow_gha_ecr_push" {
  name = "reactflow-gha-ecr-push"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::154744860201:oidc-provider/token.actions.githubusercontent.com"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:bmihaly-dev/web-app-terraform-CI-DI:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "reactflow_gha_ecr_push_policy" {
  name = "reactflow-gha-ecr-push-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:ListImages",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "reactflow_attach" {
  role       = aws_iam_role.reactflow_gha_ecr_push.name
  policy_arn = aws_iam_policy.reactflow_gha_ecr_push_policy.arn
}