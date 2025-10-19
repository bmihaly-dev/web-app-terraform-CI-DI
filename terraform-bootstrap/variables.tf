variable "project" {
  description = "Rövid projektazonosító (pl. web-app-tfcicd)"
  type        = string
}

variable "aws_region" {
  description = "AWS régió a backend erőforrásokhoz"
  type        = string
  default     = "eu-central-1"
}

variable "ecr_repository" {
  description = "ECR repo name for the app image"
  type        = string
  default     = "reactflow"
}

variable "gh_owner" {
  description = "GitHub repository user"
  type        = string
}

variable "gh_repo" {
  description = "GitHub repository name"
  type        = string  
  
}