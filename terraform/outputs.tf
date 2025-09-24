output "service_name" {
  description = "App Runner szolgáltatás neve"
  value       = aws_apprunner_service.this.service_name
}

output "service_arn" {
  description = "App Runner szolgáltatás ARN"
  value       = aws_apprunner_service.this.arn
}

output "service_url" {
  description = "Publikus URL (HTTPS)"
  value       = aws_apprunner_service.this.service_url
}