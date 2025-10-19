

data "aws_caller_identity" "me" {}
data "aws_region" "current" {}


resource "aws_ecr_repository" "app" {
  name                 = var.project
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  encryption_configuration { encryption_type = "AES256" }

  force_delete = true

  tags = { Project = var.project }

}


resource "aws_ecr_lifecycle_policy" "keep_recent" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1,
      description  = "Keep last 10 images",
      selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 10 },
      action       = { type = "expire" }
    }]
  })
}


resource "aws_iam_role" "apprunner_ecr_access" {
  name = "${var.project}-apprunner-ecr-access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "build.apprunner.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "apprunner_ecr_ro" {
  role       = aws_iam_role.apprunner_ecr_access.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


resource "aws_apprunner_service" "app" {
  count        = var.create_service ? 1 : 0
  service_name = "${var.project}-prod"

  source_configuration {
    auto_deployments_enabled = true

    image_repository {
      image_repository_type = "ECR"
      image_identifier      = "154744860201.dkr.ecr.eu-central-1.amazonaws.com/reactflow:latest"

      image_configuration {
        port = tostring(var.app_port)
        runtime_environment_variables = {
          NODE_ENV = "production"
        }
      }
    }

    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_access.arn
    }
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = "/"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 1
    unhealthy_threshold = 5
  }

  tags = { Project = var.project }
}


