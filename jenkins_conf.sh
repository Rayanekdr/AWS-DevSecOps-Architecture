#!/bin/bash

# Load SonarQube token from /tmp/sonarqube_token.env
if [ -f "/tmp/sonarqube_token.env" ]; then
  SONARQUBE_TOKEN=$(cat /tmp/sonarqube_token.env)
else
  echo "SonarQube token file /tmp/sonarqube_token.env not found. Exiting."
  exit 1
fi

# Verify that the SonarQube token was loaded successfully
if [ -z "$SONARQUBE_TOKEN" ]; then
  echo "Failed to load SonarQube token. Exiting."
  exit 1
fi
echo "SonarQube token successfully loaded."


# Retrieve the public IP address of Jenkins
JENKINS_PUBLIC_IP=$(cat /home/ubuntu/public_ip.txt)

# Verify that the public IP was retrieved successfully
if [ -z "$JENKINS_PUBLIC_IP" ]; then
  echo "Failed to retrieve Jenkins public IP. Exiting."
  exit 1
fi
echo "Jenkins Public IP: $JENKINS_PUBLIC_IP"

# Function to check if Jenkins is up and running
wait_for_jenkins() {
  until curl -s -o /dev/null -w "%{http_code}" "http://$JENKINS_PUBLIC_IP:8080/login" | grep -q "200"; do
    echo "Waiting for Jenkins to be up..."
    sleep 10
  done
}

# Wait for Jenkins to be up
echo "Checking if Jenkins is up..."
wait_for_jenkins
echo "Jenkins is up."

# Get Jenkins initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword > /tmp/initialAdminPassword
JENKINS_ADMIN_PASSWORD=$(cat /tmp/initialAdminPassword)
echo "Jenkins initial admin password: $JENKINS_ADMIN_PASSWORD"

# Verify the environment variable is set
if [ -z "$JENKINS_ADMIN_PASSWORD" ]; then
  echo "Failed to set Jenkins admin password. Exiting."
  exit 1
fi

# Get Jenkins crumb (CSRF token)
JENKINS_CRUMB=$(curl -s -u "admin:$JENKINS_ADMIN_PASSWORD" "http://$JENKINS_PUBLIC_IP:8080/crumbIssuer/api/json" | jq -r '.crumb')
if [ -z "$JENKINS_CRUMB" ]; then
  echo "Failed to get Jenkins crumb. Exiting."
  exit 1
fi
echo "Jenkins crumb: $JENKINS_CRUMB"

echo "Installing JENKINS CLI"
wget -q http://$JENKINS_PUBLIC_IP:8080/jnlpJars/jenkins-cli.jar -O /home/ubuntu/jenkins-cli.jar
if [ $? -ne 0 ]; then
  echo "Failed to download Jenkins CLI jar. Exiting."
  exit 1
fi
echo "JENKINS CLI installed successfully"

# Assign the CLI JAR path to a variable
CLI_JAR="/home/ubuntu/jenkins-cli.jar"

# Step 1: Install Custom Plugins
PLUGINS=(
  "credentials"
  "credentials-binding"
  "jdk-tool"
  "workflow-job"
  "workflow-aggregator"
  "git"
  "pipeline-groovy-lib"
  "nodejs"
  "sonar"
  "adoptopenjdk"
  "docker-plugin"
  "docker-commons"
  "docker-workflow"
  "docker-java-api"
  "docker-build-step"
  "dependency-check-jenkins-plugin"
  "ws-cleanup"
  "email-ext"
  # Default plugins suggested by Jenkins
  "ant"
  "bouncycastle-api"
  "branch-api"
  "build-timeout"
  "cloudbees-folder"
  "command-launcher"
  "credentials"
  "display-url-api"
  "durable-task"
  "git-client"
  "git-server"
  "icon-shim"
  "junit"
  "mailer"
  "matrix-auth"
  "matrix-project"
  "momentjs"
  "pipeline-build-step"
  "pipeline-input-step"
  "pipeline-stage-step"
  "pipeline-stage-view"
  "plain-credentials"
  "scm-api"
  "script-security"
  "ssh-credentials"
  "structs"
  "timestamper"
  "token-macro"
  "workflow-cps"
  "workflow-durable-task-step"
  "workflow-multibranch"
  "workflow-scm-step"
  "workflow-step-api"
  "workflow-support"
  # Additional plugins from your categories
  "dashboard-view"
  "configuration-as-code"
  "antisamy-markup-formatter"
  "build-name-setter"
  "config-file-provider"
  "embeddable-build-status"
  "rebuild"
  "ssh-agent"
  "throttle-concurrents"
  "gradle"
  "msbuild"
  "cobertura"
  "htmlpublisher"
  "warnings-ng"
  "xunit"
  "github-branch-source"
  "pipeline-github-lib"
  "conditional-buildstep"
  "parameterized-trigger"
  "copyartifact"
)


echo "Installing Jenkins plugins..."
for plugin in "${PLUGINS[@]}"; do
  java -jar $CLI_JAR -s http://$JENKINS_PUBLIC_IP:8080 -auth admin:$JENKINS_ADMIN_PASSWORD install-plugin $plugin
  if [ $? -ne 0 ]; then
    echo "Failed to install plugin: $plugin. Continuing with the next plugin."
  fi
done

# Restart Jenkins to apply plugins
echo "Restarting Jenkins..."
java -jar $CLI_JAR -s http://$JENKINS_PUBLIC_IP:8080 -auth admin:$JENKINS_ADMIN_PASSWORD safe-restart

# Wait for Jenkins to restart
echo "Waiting for Jenkins to restart..."
until curl -s -o /dev/null -w "%{http_code}" "http://$JENKINS_PUBLIC_IP:8080/login" | grep -q "200"; do
  echo "Jenkins is restarting. Please wait..."
  sleep 10
done
echo "Jenkins restarted successfully."

# Step 2: Add SonarQube token credential
echo "Adding SonarQube token credential..."
java -jar $CLI_JAR -s http://$JENKINS_PUBLIC_IP:8080 -auth admin:$JENKINS_ADMIN_PASSWORD groovy = <<EOF
import jenkins.model.*
import hudson.util.Secret
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*
import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl

def domain = Domain.global()
def store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

// Check if credential already exists
def existing = store.getCredentials(domain).find { it.id == 'Sonar-token' }
if (!existing) {
    def secretText = new StringCredentialsImpl(
        CredentialsScope.GLOBAL,
        'Sonar-token',
        'Sonar-token',
        Secret.fromString("${SONARQUBE_TOKEN}")
    )
    store.addCredentials(domain, secretText)
    println "SonarQube token added successfully."
} else {
    println "SonarQube token credential already exists."
}
EOF

# Step 3: Add Docker Hub credentials
echo "Adding Docker Hub credentials..."
java -jar $CLI_JAR -s http://$JENKINS_PUBLIC_IP:8080 -auth admin:$JENKINS_ADMIN_PASSWORD groovy = <<EOF
import jenkins.model.*
import hudson.util.Secret
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.plugins.credentials.impl.*

def domain = Domain.global()
def store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()
def usernamePassword = new UsernamePasswordCredentialsImpl(
  CredentialsScope.GLOBAL,
  'docker',
  'docker',
  'rayanekhadraoui',
  'Troyesfrkdr13@'
)
store.addCredentials(domain, usernamePassword)
EOF


# Read the email password from the file
EMAIL_PASSWORD=$(cat /home/ubuntu/emailP.txt)
# Step 3-1: Add email credentials under Tools
echo "Adding email credentials ......"
java -jar $CLI_JAR -s http://$JENKINS_PUBLIC_IP:8080 -auth admin:$JENKINS_ADMIN_PASSWORD groovy = <<EOF
import jenkins.model.*
import hudson.plugins.emailext.*
import hudson.plugins.emailext.plugins.*
import hudson.plugins.emailext.plugins.trigger.*

def instance = Jenkins.getInstance()

// Configure E-mail Notification
def mailer = instance.getDescriptorByType(hudson.tasks.Mailer.DescriptorImpl)
mailer.setSmtpHost("smtp.gmail.com")
mailer.setDefaultSuffix("rayanetlm.com0@gmail.com")
mailer.setSmtpAuth("rayanetlm.com0@gmail.com", "${EMAIL_PASSWORD}")
mailer.setUseSsl(true)
mailer.setSmtpPort("465")
mailer.save()
EOF



echo "Configuring SonarQube scanner..."
java -jar $CLI_JAR -s http://$JENKINS_PUBLIC_IP:8080 -auth admin:$JENKINS_ADMIN_PASSWORD groovy = <<EOF
import jenkins.model.*
import hudson.plugins.sonar.*
import hudson.plugins.sonar.model.TriggersConfig
import hudson.util.Secret

def inst = Jenkins.getInstance()
def desc = inst.getDescriptorByType(hudson.plugins.sonar.SonarGlobalConfiguration.class)

def sonarInst = new SonarInstallation(
  "sonar-server",  // Name of the SonarQube scanner
  "http://$JENKINS_PUBLIC_IP:9000",              
  "Sonar-token",    // Credentials ID
  null,             // Server authentication token (null if not used)
  null,             // Webhook secret ID (null if not used)
  "",               // Mojo version (leave empty if not needed)
  "",               // Additional properties (leave empty if not needed)
  "",               // Additional analysis properties (leave empty if not needed)
  new TriggersConfig()  // Triggers configuration
)

// Set the SonarQube installation
desc.setInstallations(sonarInst)
desc.save()
// Verify the installation
def installations = desc.getInstallations()
println "Current SonarQube installations: " + installations.collect { it.getName() }

inst.save()
EOF

# Step 4: Configure SonarQube Scanner
echo "Configuring SonarQube scanner..."
java -jar $CLI_JAR -s http://$JENKINS_PUBLIC_IP:8080 -auth admin:$JENKINS_ADMIN_PASSWORD groovy = <<EOF
import jenkins.model.*
import hudson.tools.*

// Define SonarQube Scanner name and version
def sonarScannerName = "sonar-scanner"
def sonarScannerVersion = "6.2.0.4584"

// Get the Jenkins instance
def jenkins = Jenkins.getInstanceOrNull()
if (jenkins == null) {
    println "Jenkins instance is not available. Exiting."
    return
}

// Access the global tool configuration
def descriptor = jenkins.getDescriptorByType(hudson.plugins.sonar.SonarRunnerInstallation.DescriptorImpl.class)

// Check if the SonarQube Scanner is already configured
def existingInstallations = descriptor.getInstallations()
def existingScanner = existingInstallations.find { it.getName() == sonarScannerName }

if (existingScanner) {
    println "SonarQube Scanner '${sonarScannerName}' is already configured."
    // Update the installation source if the version does not match
    def installSource = existingScanner.getProperties().find { it instanceof InstallSourceProperty }
    if (installSource && !installSource.installers.find { it.id == sonarScannerVersion }) {
        println "Updating SonarQube Scanner '${sonarScannerName}' to version ${sonarScannerVersion}."
        installSource.installers.clear()
        installSource.installers.add(new hudson.plugins.sonar.SonarRunnerInstaller(sonarScannerVersion))
        descriptor.save()
        println "SonarQube Scanner '${sonarScannerName}' has been updated to version ${sonarScannerVersion}."
    } else {
        println "SonarQube Scanner '${sonarScannerName}' is already set to the desired version."
    }
} else {
    println "Adding new SonarQube Scanner '${sonarScannerName}' with version ${sonarScannerVersion}."
    def sonarScannerInstaller = new hudson.plugins.sonar.SonarRunnerInstaller(sonarScannerVersion)
    def installSource = new InstallSourceProperty([sonarScannerInstaller])
    def newScanner = new hudson.plugins.sonar.SonarRunnerInstallation(sonarScannerName, "", [installSource])
    descriptor.setInstallations((existingInstallations + newScanner) as hudson.plugins.sonar.SonarRunnerInstallation[])
    descriptor.save()
    println "SonarQube Scanner '${sonarScannerName}' has been successfully configured with version ${sonarScannerVersion}."
}
EOF

# Read the email password from the file
EMAIL_PASSWORD=$(cat /home/ubuntu/emailP.txt)
# Step 4-1: Configure Extended E-mail Notification
echo "Configuring Extended E-mail Notification......"
java -jar $CLI_JAR -s http://$JENKINS_PUBLIC_IP:8080 -auth admin:$JENKINS_ADMIN_PASSWORD groovy = <<EOF
import jenkins.model.*
import hudson.plugins.emailext.*
import hudson.plugins.emailext.plugins.*
import hudson.plugins.emailext.plugins.trigger.*
import hudson.plugins.emailext.plugins.recipients.*

def instance = Jenkins.getInstance()

// Configure Extended E-mail Notification
def emailExt = instance.getDescriptorByType(ExtendedEmailPublisherDescriptor.class)
emailExt.setSmtpServer("smtp.gmail.com")
emailExt.setSmtpPort("465")
emailExt.setCharset("UTF-8")
emailExt.setDefaultContentType("text/html")
emailExt.setDefaultRecipients("rayanetlm.com0@gmail.com")
emailExt.setDefaultReplyTo("rayanetlm.com0@gmail.com")
emailExt.setDefaultSubject("Build Notification")
emailExt.setDefaultBody("Build status: \${BUILD_STATUS}")
emailExt.setUseSsl(true)
emailExt.setSmtpAuth("rayanetlm.com0@gmail.com", "${EMAIL_PASSWORD}")

// Set default triggers
def alwaysTrigger = new AlwaysTrigger(
    [new DevelopersRecipientProvider()], // List of recipient providers
    "", // Recipient list
    "", // Reply-to
    "", // Subject
    "", // Body
    "", // Attachments pattern
    0,  // Attach build log
    "text/html" // Content type
)

def failureTrigger = new FailureTrigger(
    [new RequesterRecipientProvider()], // List of recipient providers
    "", // Recipient list
    "", // Reply-to
    "", // Subject
    "", // Body
    "", // Attachments pattern
    0,  // Attach build log
    "text/html" // Content type
)

// Add triggers to the list
def triggerIds = ["hudson.plugins.emailext.plugins.trigger.AlwaysTrigger", "hudson.plugins.emailext.plugins.trigger.FailureTrigger"]
emailExt.setDefaultTriggerIds(triggerIds)
emailExt.save()
EOF


# Step 5: Configure NodeJS and JDK installations
echo "Configuring NodeJS and JDK tools..."
java -jar $CLI_JAR -s http://$JENKINS_PUBLIC_IP:8080 -auth admin:$JENKINS_ADMIN_PASSWORD groovy = <<EOF
import jenkins.model.*
import hudson.tools.*
import jenkins.plugins.nodejs.tools.*
import hudson.model.JDK
import io.jenkins.plugins.adoptopenjdk.AdoptOpenJDKInstaller

def inst = Jenkins.getInstance()

// Configure NodeJS installation
def nodeDesc = inst.getDescriptorByType(jenkins.plugins.nodejs.tools.NodeJSInstallation.DescriptorImpl.class)
def nodeInst = new NodeJSInstallation(
    "node16", // Name
    "",       // Path to installation (auto-installed in this case)
    [new InstallSourceProperty([new NodeJSInstaller("16.2.0", null, 72)])] // Version 16.2.0, no npm packages, refresh every 72 hours
)
nodeDesc.setInstallations(nodeInst)
nodeDesc.save()
println "NodeJS configured successfully."

// Configure JDK installation from Adoptium (Eclipse Temurin)
final versions = [
    'jdk17': 'jdk-17.0.8.1+1'
]

def jdkDesc = inst.getDescriptorByType(hudson.model.JDK.DescriptorImpl.class)
def jdkInst = versions.collect {
    new JDK(it.key, '', [
        new InstallSourceProperty([
            new AdoptOpenJDKInstaller(it.value)
        ])
    ])
} as JDK[]

jdkDesc.setInstallations(jdkInst)
jdkDesc.save()
println "JDK configured successfully."

// Save the Jenkins instance configuration
inst.save()
EOF


# Step 6: Configure Dependency-Check tool with automatic installation
echo "Configuring Dependency-Check tool..."
java -jar $CLI_JAR -s http://$JENKINS_PUBLIC_IP:8080 -auth admin:$JENKINS_ADMIN_PASSWORD groovy = <<EOF
import jenkins.model.*
import org.jenkinsci.plugins.DependencyCheck.tools.DependencyCheckInstallation
import org.jenkinsci.plugins.DependencyCheck.tools.DependencyCheckInstaller
import hudson.tools.InstallSourceProperty

def instance = Jenkins.getInstance()
def descriptor = instance.getDescriptorByType(org.jenkinsci.plugins.DependencyCheck.tools.DependencyCheckInstallation.DescriptorImpl.class)
def installations = descriptor.getInstallations() as List

// Use the specific version 8.4.0 of Dependency-Check
def installer = new org.jenkinsci.plugins.DependencyCheck.tools.DependencyCheckInstaller("8.4.0")
def installSourceProperty = new hudson.tools.InstallSourceProperty([installer])
def newInstallation = new org.jenkinsci.plugins.DependencyCheck.tools.DependencyCheckInstallation("DP-Check", "", [installSourceProperty])

// Add the new installation
installations.add(newInstallation)

descriptor.setInstallations(installations.toArray(new org.jenkinsci.plugins.DependencyCheck.tools.DependencyCheckInstallation[0]))
descriptor.save()

// Save the Jenkins instance configuration
instance.save()
EOF

if [ $? -ne 0 ]; then
  echo "Failed to configure Dependency-Check tool."
else
  echo "Dependency-Check tool configured successfully."
fi

# Step 7: Configure Docker
echo "Configuring Docker tool..."
java -jar $CLI_JAR -s http://$JENKINS_PUBLIC_IP:8080 -auth admin:$JENKINS_ADMIN_PASSWORD groovy = <<EOF
import jenkins.model.*
import hudson.model.*
import hudson.tools.*
import org.jenkinsci.plugins.docker.commons.tools.*

def inst = Jenkins.getInstance()

def desc = inst.getDescriptor("org.jenkinsci.plugins.docker.commons.tools.DockerTool")

def versions = [
  "latest": "docker"
]

def installations = []

for (v in versions) {
  def installer = new DockerToolInstaller("", v.key)
  def installerProps = new InstallSourceProperty([installer])

  def installation = new DockerTool(v.value, "", [installerProps])
  installations.push(installation)
}

desc.setInstallations(installations.toArray(new DockerTool[0]))

desc.save()

// Save the Jenkins instance configuration
inst.save()
EOF

if [ $? -ne 0 ]; then
  echo "Failed to configure Docker tool."
else
  echo "Docker tool configured successfully."
fi


# Step 8: Create a new pipeline project and configure it
echo "Creating Jenkins pipeline project 'RayaneFlix'..."

pipeline_script=$(cat /home/ubuntu/RayaneFlix-pipeline.groovy)

# Create the pipeline project
java -jar $CLI_JAR -s http://$JENKINS_PUBLIC_IP:8080 -auth admin:$JENKINS_ADMIN_PASSWORD create-job RayaneFlix <<EOF
<flow-definition plugin="workflow-job">
  <actions/>
  <description>Pipeline project for RayaneFlix</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps">
    <script><![CDATA[
${pipeline_script}
    ]]></script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

if [ $? -eq 0 ]; then
  echo "Pipeline project 'RayaneFlix' created successfully."
else
  echo "Failed to create pipeline project 'RayaneFlix'. Exiting."
  exit 1
fi

# Run the pipeline
echo "Running the 'RayaneFlix' pipeline..."
java -jar $CLI_JAR -s http://$JENKINS_PUBLIC_IP:8080 -auth admin:$JENKINS_ADMIN_PASSWORD build RayaneFlix

if [ $? -eq 0 ]; then
  echo "Pipeline 'RayaneFlix' executed successfully."
else
  echo "Failed to execute pipeline 'RayaneFlix'. Please check Jenkins for errors."
  exit 1
fi
