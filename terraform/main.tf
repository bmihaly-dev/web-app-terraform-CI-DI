locals {
  base_name   = "reactflow"
  service_env = var.env
  pr_suffix   = var.env == "preview" && var.pr_id != null ? "-pr-${var.pr_id}" : ""
  service_name = "${local.base_name}-${local.service_env}${local.pr_suffix}"

  common_tags = {
    project = "terraform-cicd"
    app     = "reactflow"
    env     = var.env
    pr      = var.pr_id != null ? var.pr_id : ""
  }
}

resource "aws_iam_role" "apprunner_access" {
  name               = "apprunner-access-${local.service_env}${local.pr_suffix}"
  assume_role_policy = data.aws_iam_policy_document.apprunner_trust.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "apprunner_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["build.apprunner.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role_policy_attachment" "apprunner_ecr_access" {
  role       = aws_iam_role.apprunner_access.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}


resource "aws_apprunner_service" "this" {
  service_name = local.service_name
  tags         = local.common_tags

  source_configuration {
    auto_deployments_enabled = true

    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_access.arn
    }

    image_repository {
      image_repository_type = "ECR"
      image_identifier      = var.image_uri

      image_configuration {
        port = "80" 
         
      }
    }
  }

  instance_configuration {
    cpu    = var.cpu
    memory = var.memory
  }

  health_check_configuration {
    protocol            = "HTTP"
    path                = var.health_check_path
    interval            = 5
    timeout             = 2
    healthy_threshold   = 1
    unhealthy_threshold = 3
  }
}