variable "project" {
  description = "Rövid projektazonosító (pl. web-app-tfcicd)"
  type        = string
}

variable "aws_region" {
  description = "AWS régió a backend erőforrásokhoz"
  type        = string
  default     = "eu-central-1"
}