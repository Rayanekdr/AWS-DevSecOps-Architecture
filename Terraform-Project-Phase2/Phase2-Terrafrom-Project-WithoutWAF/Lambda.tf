resource "aws_lambda_function" "upload_files" {
  function_name    = "upload_files"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_role.arn
  handler          = "upload_files.lambda_handler"
  filename         = "${path.module}/lambda_package.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_package.zip")
  timeout          = 10

  environment {
    variables = {
      INSTANCE_ID = aws_instance.netflix_ec2.id
      BUCKET_NAME = aws_s3_bucket.lambda_code.bucket
    }
  }

  tags = {
    Environment = "Production"
    Name        = "UploadFilesLambda"
  }
}

resource "aws_lambda_function" "install_ansible" {
  function_name    = "install_ansible"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_role.arn
  handler          = "install_ansible.lambda_handler"
  filename         = "${path.module}/lambda_package.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_package.zip")
  timeout          = 10

  environment {
    variables = {
      INSTANCE_ID = aws_instance.netflix_ec2.id
      REGION = var.region
    }
  }

  tags = {
    Environment = "Production"
    Name        = "InstallAnsibleLambda"
  }
}

resource "aws_lambda_function" "trigger_ansible" {
  function_name    = "trigger_ansible"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_role.arn
  handler          = "trigger_ansible.lambda_handler"
  s3_bucket        = aws_s3_bucket.lambda_code.bucket
  s3_key           = aws_s3_object.lambda_package.key
  source_code_hash = filebase64sha256("${path.module}/lambda_package.zip")
  timeout          = 10

  environment {
    variables = {
      INSTANCE_ID = aws_instance.netflix_ec2.id
      REGION      = var.region
      BUCKET_NAME = aws_s3_bucket.lambda_code.bucket
    }
  }

  tags = {
    Environment = "Production"
    Name        = "TriggerAnsibleLambda"
  }
}
