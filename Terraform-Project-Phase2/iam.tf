resource "aws_iam_role" "ssm_role" {
  name = "SSMRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_role_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "lambda_role" {
  name = "LambdaExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect: "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "LambdaPolicy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect: "Allow",
        Action = [
          "ssm:SendCommand",
          "ssm:ListCommandInvocations",
          "ssm:GetCommandInvocation",
          "s3:PutObject",
          "s3:GetObject",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_ssm_access_policy" {
  name        = "S3SSMAccessPolicy"
  description = "Policy to allow S3 and SSM access for EC2 instance"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect: "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::lambda-code-bucket-rayane",
          "arn:aws:s3:::lambda-code-bucket-rayane/*"
        ]
      },
      {
        Effect: "Allow",
        Action = [
          "ssm:SendCommand",
          "ssm:ListCommandInvocations",
          "ssm:GetCommandInvocation",
          "ssm:DescribeInstanceInformation"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "ec2_role" {
  name = "EC2Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect: "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_role_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_ssm_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2InstanceProfile"
  role = aws_iam_role.ec2_role.name
}