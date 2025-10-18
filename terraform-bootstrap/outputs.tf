output "tf_backend_bucket" {
  description = "Terraform state bucket neve"
  value       = aws_s3_bucket.tf_state.bucket
}

output "tf_lock_table" {
  description = "DynamoDB lock tábla neve"
  value       = aws_dynamodb_table.tf_lock.name
}

output "example_tfstate_key" {
  description = "state file útvonal"
  value       = "dev/${var.project}/terraform.tfstate"
}