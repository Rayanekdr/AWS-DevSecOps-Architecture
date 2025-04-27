resource "aws_ssm_document" "check_and_trigger" {
  name          = "CheckAndTrigger"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Check internet connectivity and trigger Lambda functions",
    mainSteps = [
      {
        action = "aws:runShellScript",
        name   = "checkAndTrigger",
        inputs = {
          runCommand = [
            "ping -c 4 google.com",
            "if [ $? -eq 0 ]; then",
            "  echo 'Ping successful. Triggering Lambda functions...'",
            "  aws lambda invoke --function-name upload_files --region eu-west-3 --payload '{}' output.txt",
            "  aws lambda invoke --function-name install_ansible --region eu-west-3 --payload '{}' output.txt",
            "  aws lambda invoke --function-name trigger_ansible_playbook --region eu-west-3 --payload '{}' output.txt",
            "else",
            "  echo 'Ping failed. Exiting...'",
            "  exit 1",
            "fi"
          ]
        }
      }
    ]
  })
}

resource "aws_ssm_association" "check_and_trigger" {
  name = aws_ssm_document.check_and_trigger.name

  targets {
    key    = "InstanceIds"
    values = [aws_instance.netflix_ec2.id]
  }

  depends_on = [
    aws_instance.netflix_ec2,
    aws_cloudfront_distribution.rayaneflix,
    aws_lb.main,
    aws_lambda_function.upload_files,
    aws_lambda_function.install_ansible,
    aws_lambda_function.trigger_ansible
  ]
}
*/