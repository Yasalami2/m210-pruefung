provider "aws" { region = "us-east-1" }

resource "aws_dynamodb_table" "db" {
  name         = "AutoTableQuick"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  
  attribute {
    name = "id"
    type = "S"
  }
}

data "aws_iam_role" "lab" { 
  name = "LabRole" 
}

resource "aws_lambda_function" "api" {
  filename      = "backend_code.zip"
  function_name = "AutoAPI_QuickFix"
  role          = data.aws_iam_role.lab.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
}
