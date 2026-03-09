provider "aws" { region = "us-east-1" }

# Datenbank
resource "aws_dynamodb_table" "db" {
  name         = "PruefungDB"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attribute {
    name = "id"
    type = "S"
  }
}

# Nutzt die vorhandene Rolle im Learner Lab
data "aws_iam_role" "lab" { name = "LabRole" }

# Die Lambda Funktion
resource "aws_lambda_function" "api" {
  filename      = "backend_code.zip"
  function_name = "PruefungAPI"
  role          = data.aws_iam_role.lab.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
}

# Falls Terraform die URL verwalten soll (sicherheitshalber drin lassen)
resource "aws_lambda_function_url" "url" {
  function_name      = aws_lambda_function.api.function_name
  authorization_type = "NONE"
  cors { allow_origins = ["*"] }
}

output "api_url" { value = aws_lambda_function_url.url.function_url }
