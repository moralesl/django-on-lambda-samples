output "api_endpoint" {
  value = replace(aws_api_gateway_stage.main.invoke_url, "/$default", "")
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "aurora_endpoint" {
  value = aws_rds_cluster.aurora.endpoint
}

output "aurora_port" {
  value = aws_rds_cluster.aurora.port
}
