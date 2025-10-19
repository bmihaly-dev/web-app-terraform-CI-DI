variable "aws_region" {
  
  type        = string
}

variable "env" {
  description = "Környezet: dev, preview vagy prod"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "preview", "prod"], var.env)
    error_message = "env csak 'dev', 'preview' vagy 'prod' lehet."
  }
}

variable "pr_id" {
  description = "PR azonosító preview esetén (pl. 123). Prodnál üres."
  type        = string
  default     = null
}

variable "image_uri" {
  description = "ECR image URI + tag (pl. 123456789012.dkr.ecr.eu-central-1.amazonaws.com/reactflow-app:pr-123-a1b2c3)"
  type        = string
  default     = "154744860201.dkr.ecr.eu-central-1.amazonaws.com/reactflow-app:1.0.0"
}

variable "cpu" {
  description = "App Runner CPU (1024|2048)"
  type        = number
  default     = 1024
}

variable "memory" {
  description = "App Runner memória (2048|3072|4096)"
  type        = number
  default     = 2048
}

variable "health_check_path" {
  
  type        = string
  default     = "/"
}

variable "env_vars" {
  description = "Opcionális környezeti változók a konténerhez"
  type        = map(string)
  default     = {}
}
variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "github_owner" {
  type = string
  # pl. "bmihaly-dev"
}

variable "github_repo" {
  type = string
  # pl. "terraform-CICD"
}

variable "tf_backend_bucket" {
  type = string

}

variable "tf_backend_key" {
  type = string

}

variable "backend_dynamodb_table" {
  type = string
}
variable "project_name" {
  type = string
}
variable "tf_lock_table" {
  type = string

}
variable "create_service" {
  type    = bool
  default = false
}

variable "project" {
  type    = string
  default = "reactflow"
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "image_tag" {
  type    = string
  default = "latest"
}