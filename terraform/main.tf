locals {
  base_name    = "reactflow"
  service_env  = var.env
  pr_suffix    = var.env == "preview" && var.pr_id != null ? "-pr-${var.pr_id}" : ""
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





