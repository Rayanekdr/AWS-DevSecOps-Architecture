import json
import boto3

def lambda_handler(event, context):
    ssm_client = boto3.client('ssm', region_name="eu-west-3")
    instance_id = event.get('INSTANCE_ID')
    
    if not instance_id:
        print("Error: INSTANCE_ID not found in the event")
        return {'statusCode': 400, 'body': 'INSTANCE_ID not found in the event'}

    commands = [
        "sudo apt update",
        "sudo apt install -y software-properties-common",
        "sudo add-apt-repository --yes --update ppa:ansible/ansible",
        "sudo apt install -y ansible python3-venv"
    ]

    try:
        response = ssm_client.send_command(
            InstanceIds=[instance_id],
            DocumentName="AWS-RunShellScript",
            Parameters={"commands": commands},
            TimeoutSeconds=300,
            Comment="Installing Ansible on the instance"
        )
        command_id = response['Command']['CommandId']
        print(f"SSM Command {command_id} sent to instance {instance_id}")
    except Exception as e:
        print(f"Error sending command: {e}")
        return {'statusCode': 500, 'body': f"Error sending command: {e}"}

    return {
        'statusCode': 200,
        'body': json.dumps('Ansible installation initiated successfully!')
    }
