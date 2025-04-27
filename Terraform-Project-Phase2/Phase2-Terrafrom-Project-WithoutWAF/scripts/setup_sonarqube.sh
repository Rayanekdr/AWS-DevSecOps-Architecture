#!/bin/bash

# Wait for SonarQube to be ready
sleep 120

# Verify SonarQube authentication
AUTH_RESPONSE=$(curl -u admin:admin -s -o /dev/null -w "%{http_code}" http://localhost:9000/api/authentication/validate)
if [ "$AUTH_RESPONSE" -ne 200 ]; then
  echo "SonarQube authentication failed"
  exit 1
fi

# Change SonarQube default password
curl -u admin:admin -X POST -d "login=admin&previousPassword=admin&password=new_secure_password" http://localhost:9000/api/users/change_password

# Verify SonarQube authentication with new password
AUTH_RESPONSE_NEW=$(curl -u admin:new_secure_password -s -o /dev/null -w "%{http_code}" http://localhost:9000/api/authentication/validate)
if [ "$AUTH_RESPONSE_NEW" -ne 200 ]; then
  echo "SonarQube authentication with new password failed"
  exit 1
fi

# Create SonarQube token
SONARQUBE_TOKEN=$(curl -u admin:new_secure_password -X POST -d "name=Jenkins" -s http://localhost:9000/api/user_tokens/generate | jq -r .token)
if [ -z "$SONARQUBE_TOKEN" ]; then
  echo "Failed to create SonarQube token"
  exit 1
fi

# Export the token to be used in Ansible
echo "$SONARQUBE_TOKEN" > /tmp/sonarqube_token.env


# Create a new SonarQube project named RayaneFlix
PROJECT_KEY="RayaneFlix"
PROJECT_NAME="RayaneFlix"

CREATE_PROJECT_RESPONSE=$(curl -u admin:new_secure_password -X POST -d "project=$PROJECT_KEY&name=$PROJECT_NAME" -s -o /dev/null -w "%{http_code}" http://localhost:9000/api/projects/create)
if [ "$CREATE_PROJECT_RESPONSE" -ne 200 ]; then
  echo "Failed to create SonarQube project '$PROJECT_NAME'."
  exit 1
fi
echo "SonarQube project '$PROJECT_NAME' created successfully."