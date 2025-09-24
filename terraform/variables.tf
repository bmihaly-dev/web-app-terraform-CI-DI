variable "aws_region" {
  description = "AWS régió, pl. eu-central-1"
  type        = string
}

variable "env" {
  description = "Környezet: prod vagy preview"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["prod", "preview"], var.env)
    error_message = "env csak 'prod' vagy 'preview' lehet."
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
  description = "Health check HTTP path (statikus appnál maradhat /)"
  type        = string
  default     = "/"
}

variable "env_vars" {
  description = "Opcionális környezeti változók a konténerhez"
  type        = map(string)
  default     = {}
}