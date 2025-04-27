import json
import boto3

def lambda_handler(event, context):
    ssm_client = boto3.client('ssm', region_name="eu-west-3")
    instance_id = event.get('INSTANCE_ID')
    
    if not instance_id:
        return {'statusCode': 400, 'body': 'INSTANCE_ID not found in the event'}
    
    s3_bucket = "lambda-code-bucket-rayane"
    files_to_copy = [
        "setup_ec2.yml",
        "RayaneFlix-pipeline.groovy",
        "emailP.txt",
        "setup_sonarqube.sh",
        "jenkins_conf.sh"
    ]
    
    commands = [
        f"aws s3 cp s3://{s3_bucket}/{file} /home/ubuntu/{file}" for file in files_to_copy
    ]
    
    try:
        response = ssm_client.send_command(
            InstanceIds=[instance_id],
            DocumentName="AWS-RunShellScript",
            Parameters={"commands": commands},
            TimeoutSeconds=300,
            Comment="Copying files from S3 to EC2 instance"
        )
        command_id = response['Command']['CommandId']
        print(f"SSM Command {command_id} sent to instance {instance_id}")
    except Exception as e:
        return {'statusCode': 500, 'body': f"Error sending command: {e}"}
    
    return {
        'statusCode': 200,
        'body': json.dumps('Files copy initiated successfully!')
    }