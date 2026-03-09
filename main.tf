provider "aws" { region = "us-east-1" }

resource "aws_dynamodb_table" "db" {
  name = "AutoDB-Quick"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "id"
  attribute { name = "id", type = "S" }
}

data "aws_iam_role" "lab" { name = "LabRole" }

resource "aws_lambda_function" "api" {
  filename      = "backend_code.zip"
  function_name = "QuickAPI"
  role          = data.aws_iam_role.lab.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
}

resource "aws_lambda_function_url" "url" {
  function_name      = aws_lambda_function.api.function_name
  authorization_type = "NONE"
  cors { allow_origins = ["*"] }
}

# DAS ZEIGT DIR DIE URL AN:
output "api_url" {
  value = aws_lambda_function_url.url.function_url
}
