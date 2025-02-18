provider "aws" {
  region = var.aws_region
}

# VPC and Network Configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-private-${count.index + 1}"
  }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-public-${count.index + 1}"
  }
}

# RDS PostgreSQL Instance
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }
}

resource "aws_db_instance" "postgresql" {
  identifier           = "${var.project_name}-db"
  engine              = "postgres"
  engine_version      = "17.2"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  storage_encrypted   = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot = true
}

# Lambda Function
resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-lambda-sg"
  description = "Security group for Lambda function"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "django" {
  filename         = "../deployment-package.zip"
  function_name    = var.project_name
  role            = aws_iam_role.lambda.arn
  handler         = "handler.lambda_handler"
  runtime         = "python3.12"
  timeout         = 30
  memory_size     = 1024
  architectures = ["arm64"]

  //source_code_hash = filebase64sha256("../deployment-package.zip")

  environment {
    variables = {
      DJANGO_SETTINGS_MODULE = "core.settings"
      DB_NAME               = var.db_name
      DB_USER               = var.db_username
      DB_PASSWORD          = var.db_password
      DB_HOST              = aws_db_instance.postgresql.endpoint
      DJANGO_SECRET_KEY    = var.django_secret_key
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }
}

resource "aws_lambda_function" "django_snapstart" {
  filename         = "../deployment-package.zip"
  function_name    = "${var.project_name}-snapstart"
  role             = aws_iam_role.lambda.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 1024
  architectures    = ["arm64"]
  
  # Enable SnapStart for faster cold starts
  snap_start {
    apply_on = "PublishedVersions"
  }
  publish = true

  # Uncomment to enable source code hash checking
  source_code_hash = filebase64sha256("../deployment-package.zip")

  environment {
    variables = {
      DJANGO_SETTINGS_MODULE = "core.settings"
      DB_NAME                = var.db_name
      DB_USER                = var.db_username
      DB_PASSWORD            = var.db_password
      DB_HOST                = aws_db_instance.postgresql.endpoint
      DJANGO_SECRET_KEY      = var.django_secret_key
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  tags = {
    Name      = "${var.project_name}-lambda-snapstart"
    SnapStart = "true"
  }
}

resource "aws_ecr_repository" "psycopg-docker-app" {
  name                 = "${var.project_name}-psycopg-docker-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_lambda_function" "setup_db" {
  filename        = "../deployment-package.zip"
  function_name   = "${var.project_name}-setup-db"
  role            = aws_iam_role.lambda.arn
  handler         = "handler.setup_db"
  runtime         = "python3.12"
  timeout         = 300
  memory_size     = 256
  architectures   = ["arm64"]

  //source_code_hash = filebase64sha256("../deployment-package.zip")

  environment {
    variables = {
      DJANGO_SUPERUSER_USERNAME = "admin"
      DJANGO_SUPERUSER_EMAIL    = "admin@example.com"
      DJANGO_SUPERUSER_PASSWORD = var.db_password
      DJANGO_SETTINGS_MODULE    = "core.settings"
      # Database settings
      DB_NAME               = var.db_name
      DB_USER               = var.db_username
      DB_PASSWORD          = var.db_password
      DB_HOST              = aws_db_instance.postgresql.endpoint
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }
}

resource "aws_lambda_function" "check_migrations" {
  filename        = "../deployment-package.zip"
  function_name   = "${var.project_name}-check-migrations"
  role            = aws_iam_role.lambda.arn
  handler         = "handler.check_migrations"
  runtime         = "python3.12"
  timeout         = 300
  memory_size     = 256
  architectures   = ["arm64"]

  //source_code_hash = filebase64sha256("../deployment-package.zip")

  environment {
    variables = {
      DJANGO_SETTINGS_MODULE    = "core.settings"
      # Database settings
      DB_NAME               = var.db_name
      DB_USER               = var.db_username
      DB_PASSWORD          = var.db_password
      DB_HOST              = aws_db_instance.postgresql.endpoint
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }
}

# API Gateway
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "main" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "AWS_PROXY"

  integration_uri    = aws_lambda_function.django.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "main" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.main.id}"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.django.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
