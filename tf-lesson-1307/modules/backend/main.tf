resource "aws_s3_bucket" "terraform_backend" {
  bucket = "tf-lesson-1307-backend-${terraform.workspace}"
  
  lifecycle {
    prevent_destroy = false
  }
  force_destroy = true

  tags = {
    Name        = "Remote terraform backend"
    Environment = terraform.workspace
  }
  
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_backend.id
  versioning_configuration {
    status = "Enabled"
  }
  
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encription" {
  bucket = aws_s3_bucket.terraform_backend.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_stage_locks" {
  name         = "tf-lesson-1307-locks"
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Remote terraform state locks"
  }
}