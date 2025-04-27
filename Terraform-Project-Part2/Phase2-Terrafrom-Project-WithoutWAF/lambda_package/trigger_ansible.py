import json
import boto3

def lambda_handler(event, context):
    ssm_client = boto3.client('ssm', region_name="eu-west-3")
    parameter_name = "/netflix_ec2/instance_id"
    
    try:
        parameter = ssm_client.get_parameter(Name=parameter_name)
        instance_id = parameter['Parameter']['Value']
    except Exception as e:
        return {'statusCode': 500, 'body': f"Error retrieving parameter: {e}"}
    
    if not instance_id:
        return {'statusCode': 400, 'body': 'INSTANCE_ID not found in parameter store'}

    commands = [
        "echo -e '#!/bin/bash\nansible-playbook /home/ubuntu/setup_ec2.yml -i localhost,' > /home/ubuntu/run_playbook.sh",
        "sudo chmod +x /home/ubuntu/run_playbook.sh",
        "sudo /home/ubuntu/run_playbook.sh"
    ]

    try:
        response = ssm_client.send_command(
            InstanceIds=[instance_id],
            DocumentName="AWS-RunShellScript",
            Parameters={"commands": commands},
            TimeoutSeconds=300,
            Comment="Running the Ansible playbook"
        )
        command_id = response['Command']['CommandId']
        print(f"SSM Command {command_id} sent to instance {instance_id}")
    except Exception as e:
        print(f"Error sending command: {e}")
        return {'statusCode': 500, 'body': f"Error sending command: {e}"}

    return {
        'statusCode': 200,
        'body': json.dumps('Ansible playbook execution initiated successfully!')
    }