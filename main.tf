# 1. GRUNDLAGEN
provider "aws" {
  region = "us-east-1"
}

data "aws_iam_role" "lab" {
  name = "LabRole"
}

# ---------------------------------------------------------
# 2. S3 BUCKET (Für Frontend)
# ---------------------------------------------------------
resource "aws_s3_bucket" "frontend" {
  bucket = "m210-pruefung-bucket-dein-name-123"
}

# ---------------------------------------------------------
# 3. DYNAMODB TABELLE (inklusive automatischem Eintrag!)
# ---------------------------------------------------------
resource "aws_dynamodb_table" "db" {
  name         = "PruefungDB"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# NEU: Füllt die Tabelle automatisch! Spart das JSON oder Geklicke.
resource "aws_dynamodb_table_item" "test_daten" {
  table_name = aws_dynamodb_table.db.name
  hash_key   = aws_dynamodb_table.db.hash_key
  item       = <<ITEM
  {
    "id": {"S": "1"},
    "auto": {"S": "Tesla Model 3"},
    "besitzer": {"S": "Yasalami"},
    "status": {"BOOL": true}
  }
  ITEM
}

# ---------------------------------------------------------
# 4. LAMBDA & FUNCTION URL (Das Backend)
# ---------------------------------------------------------
resource "aws_lambda_function" "api" {
  filename      = "backend_code.zip" # MUSS vorher gezippt werden!
  function_name = "PruefungAPI"
  role          = data.aws_iam_role.lab.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
}

resource "aws_lambda_function_url" "url" {
  function_name      = aws_lambda_function.api.function_name
  authorization_type = "NONE"
  cors {
    allow_origins = ["*"]
  }
}

output "lambda_url" {
  value = aws_lambda_function_url.url.function_url
}

# ---------------------------------------------------------
# 5. EC2 & APACHE (Falls ein Server verlangt wird)
# ---------------------------------------------------------
resource "aws_security_group" "web_sg" {
  name        = "Web-SG"
  description = "Erlaubt HTTP"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "webserver" {
  ami                    = "ami-0c7217cdde317cfec"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Apache Server läuft!</h1>" > /var/www/html/index.html
              EOF
}

# ---------------------------------------------------------
# 6. ECS FARGATE (Falls Container verlangt werden)
# ---------------------------------------------------------
resource "aws_ecs_cluster" "mein_cluster" {
  name = "PruefungCluster"
}

resource "aws_ecs_task_definition" "meine_task" {
  family                   = "WebTask"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.lab.arn

  container_definitions = jsonencode([
    {
      name      = "web-container"
      image     = "nginx:latest" # Hier alternativ ECR-URL
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}
