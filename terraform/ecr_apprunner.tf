############################
# Data-k a már LÉTEZŐ erőforrásokra
############################
data "aws_caller_identity" "me" {}

# ECR repo – ezt a bootstrap hozta létre (név = var.project, pl. "reactflow")
data "aws_ecr_repository" "app" {
  name = var.project
}

# App Runner ECR access role – ezt is a bootstrap hozta létre
data "aws_iam_role" "apprunner_ecr_access" {
  name = "AppRunnerECRAccessRole"
}

############################
# ECR lifecycle policy (csak hivatkozunk a meglévő repo-ra)
############################
resource "aws_ecr_lifecycle_policy" "keep_recent" {
  repository = data.aws_ecr_repository.app.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1,
      description  = "Keep last 10 images",
      selection    = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 10 },
      action       = { type = "expire" }
    }]
  })
}

############################
# App Runner service (kizárólag ez az erőforrás jön létre itt)
############################
resource "aws_apprunner_service" "app" {
  count        = var.create_service ? 1 : 0
  service_name = "${var.project}-prod"

  source_configuration {
    auto_deployments_enabled = true

    image_repository {
      image_repository_type = "ECR"
      # Dinamikus image URI: <account>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>
      image_identifier      = "${data.aws_caller_identity.me.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project}:${var.image_tag}"

      image_configuration {
        port = tostring(var.app_port)
        runtime_environment_variables = {
          NODE_ENV = "production"
        }
      }
    }

    authentication_configuration {
      # Bootstrapban létrehozott role
      access_role_arn = data.aws_iam_role.apprunner_ecr_access.arn
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