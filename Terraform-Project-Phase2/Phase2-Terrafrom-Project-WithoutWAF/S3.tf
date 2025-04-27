# S3 Bucket for Lambda Code
resource "aws_s3_bucket" "lambda_code" {
  bucket        = "lambda-code-bucket-rayane"
  force_destroy = true

  tags = {
    Environment = "Production"
    Name        = "LambdaCodeBucket"
  }
}

resource "aws_s3_object" "setup_scripts" {
  for_each     = fileset("${path.module}/scripts", "*")
  bucket       = aws_s3_bucket.lambda_code.bucket
  key          = each.value
  source       = "${path.module}/scripts/${each.value}"
  content_type = "text/plain"
  etag         = filemd5("${path.module}/scripts/${each.value}")
}

# Upload Lambda Code Package to S3
resource "aws_s3_object" "lambda_package" {
  bucket       = aws_s3_bucket.lambda_code.bucket
  key          = "lambda_package.zip"
  source       = "${path.module}/lambda_package.zip"
  content_type = "application/zip"
}
