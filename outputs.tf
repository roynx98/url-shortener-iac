# outputs.tf
output "dynamodb_table_name" {
  value = aws_dynamodb_table.url_shortener.name
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.url_shortener.arn
}
