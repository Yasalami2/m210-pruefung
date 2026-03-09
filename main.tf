provider "aws" {
  region = "us-east-1"
}

resource "aws_dynamodb_table" "cars_db" {
  name         = "Auto-Verwaltung-Final"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Kennzeichen"
  attribute {
    name = "Kennzeichen"
    type = "S"
  }
}

resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "auto-verwaltung-frontend-yasalami-final" 
}

resource "aws_s3_bucket_website_configuration" "frontend_config" {
  bucket = aws_s3_bucket.frontend_bucket.id
  index_document {
    suffix = "index.html"
  }
}

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_lambda_function" "backend" {
  filename      = "backend_code.zip"
  function_name = "AutoAPI_Final"
  role          = data.aws_iam_role.lab_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
}
