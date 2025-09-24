output "service_name" {
  description = "App Runner szolgáltatás neve"
  value       = aws_apprunner_service.this.service_name
}

output "service_url" {
  description = "Public URL of the App Runner service"
  value       = "https://${aws_apprunner_service.this.service_url}"
}

output "service_arn" {
  description = "ARN of the App Runner service"
  value       = aws_apprunner_service.this.arn
}