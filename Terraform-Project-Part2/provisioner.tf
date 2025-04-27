resource "null_resource" "invoke_lambda" {
  depends_on = [
    aws_instance.netflix_ec2,
    aws_lambda_function.upload_files,
    aws_lambda_function.install_ansible,
    aws_lambda_function.trigger_ansible
  ]

  provisioner "local-exec" {
    command = <<EOT
      aws lambda invoke --function-name upload_files \
      --region eu-west-3 --profile CLI_Kali \
      output_upload_files.txt

      aws lambda invoke --function-name install_ansible \
      --region eu-west-3 --profile CLI_Kali \
      output_install_ansible.txt

      sleep 120  # Wait for 2 minutes to ensure Ansible is installed

      aws lambda invoke --function-name trigger_ansible \
      --region eu-west-3 --profile CLI_Kali \
      output_trigger_ansible.txt
    EOT
  }

  triggers = {
    instance_id = aws_instance.netflix_ec2.id
  }
}
