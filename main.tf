provider "aws" {
  region = "eu-central-1"
}

resource "aws_dynamodb_table" "cars_db" {
  name         = "Auto-VerwaltungDB"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Kennzeichen"

  attribute {
    name = "Kennzeichen"
    type = "S"
  }
}

# Bucket-Namen muessen weltweit eindeutig sein
resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "auto-verwaltung-frontend-2024-unique-id" 
}

resource "aws_s3_bucket_website_configuration" "frontend_config" {
  bucket = aws_s3_bucket.frontend_bucket.id
  index_document {
    suffix = "index.html"
  }
}

# Achtung: "Public Read" ist fuer einfache Demos ok
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role" "lambda_role" {
  name = "AutoLambdaRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {Service = "lambda.amazonaws.com"}
    }]
  })
}

resource "aws_iam_policy" "lambda_db_access" {
  name = "AutoLambda-DynamoDBAccess"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.cars_db.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_db_to_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_db_access.arn
}

resource "aws_lambda_function" "backend" {
  filename      = "backend_code.zip"
  function_name = "AutoAPI"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
}
