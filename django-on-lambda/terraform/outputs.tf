output "api_endpoint" {
  value = aws_apigatewayv2_api.main.api_endpoint
}

output "db_endpoint" {
  value     = aws_db_instance.postgresql.endpoint
  sensitive = true
}
