output "service_name" {
  description = "App Runner service name (ha létrejött)"
  value       = length(aws_apprunner_service.app) > 0 ? aws_apprunner_service.app[0].service_name : null
}

output "service_url" {
  description = "App Runner public URL (ha létrejött)"
  value       = length(aws_apprunner_service.app) > 0 ? aws_apprunner_service.app[0].service_url : null
}

output "service_arn" {
  description = "App Runner service ARN (ha létrejött)"
  value       = length(aws_apprunner_service.app) > 0 ? aws_apprunner_service.app[0].arn : null
}