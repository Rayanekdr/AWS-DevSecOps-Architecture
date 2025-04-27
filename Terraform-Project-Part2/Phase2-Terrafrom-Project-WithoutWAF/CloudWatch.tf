/*
resource "aws_cloudwatch_event_rule" "trigger_ansible_rule" {
  name        = "TriggerAnsibleRule"
  description = "Trigger Ansible playbook on specific events"
  event_pattern = jsonencode({
    source = ["custom.ansible"]
  })
}

resource "aws_cloudwatch_event_rule" "ec2_instance_ready" {
  name = "EC2InstanceReady"
  event_pattern = jsonencode({
    "source" : ["aws.ec2"],
    "detail-type" : ["EC2 Instance State-change Notification"],
    "detail" : {
      "state" : ["running"]
    }
  })
}

resource "aws_cloudwatch_event_target" "trigger_ansible_target" {
  rule      = aws_cloudwatch_event_rule.trigger_ansible_rule.name
  target_id = "trigger_ansible_target"
  arn       = aws_lambda_function.trigger_ansible.arn
}

resource "aws_cloudwatch_event_rule" "upload_files_rule" {
  name        = "UploadFilesRule"
  description = "Trigger file upload Lambda on specific events"
  event_pattern = jsonencode({
    source = ["custom.upload"]
  })
}

resource "aws_cloudwatch_event_target" "upload_files_target" {
  rule      = aws_cloudwatch_event_rule.upload_files_rule.name
  target_id = "upload_files_target"
  arn       = aws_lambda_function.upload_files.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_trigger_ansible" {
  statement_id  = "AllowCloudWatchTriggerAnsible"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trigger_ansible.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.trigger_ansible_rule.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_upload_files" {
  statement_id  = "AllowCloudWatchUploadFiles"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_files.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.upload_files_rule.arn
}

resource "aws_cloudwatch_log_group" "trigger_ansible_logs" {
  name              = "/aws/lambda/${aws_lambda_function.trigger_ansible.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "upload_files_logs" {
  name              = "/aws/lambda/${aws_lambda_function.upload_files.function_name}"
  retention_in_days = 14
}
*/