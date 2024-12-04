pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }
    stages {
        stage('clean workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout from Git') {
            steps {
                git branch: 'main', url: 'https://github.com/Rayanekdr/UTT-RayaneFlix-Project.git'
            }
        }
        stage("Sonarqube Analysis") {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh ''' $SCANNER_HOME/bin/sonar-scanner -Dsonar.projectName=RayaneFlix\
                    -Dsonar.projectKey=RayaneFlix'''
                }
            }
        }
        stage("Wait for Analysis") {
            steps {
                script {
                    sleep(time: 1, unit: 'MINUTES')
                }
            }
        }        
        stage("quality gate") {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'Sonar-token'
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }
        stage('OWASP FS SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                //dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit --nvdApiKey 4e97e979-b4b7-44eb-9622-a42f6170dcb2', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
        stage('TRIVY FS SCAN') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }
        stage("Docker Build & Push") {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh "docker build --build-arg TMDB_V3_API_KEY=f3035698c745a4fdb0916204458f2e4d -t rayaneflix ."
                        sh "docker tag rayaneflix rayanekhadraoui/rayaneflix:latest"
                        sh "docker push rayanekhadraoui/rayaneflix:latest"
                    }
                }
            }
        }
        stage("TRIVY") {
            steps {
                sh "trivy image rayanekhadraoui/rayaneflix:latest > trivyimage.txt"
            }
        }
        stage('Deploy to container') {
            steps {
                sh 'docker run -d -p 8081:80 rayanekhadraoui/rayaneflix:latest'
            }
        }
    }
    post {
        always {
            emailext attachLog: true,
                     subject: "'${currentBuild.result}'",
                     body: "Project: ${env.JOB_NAME}<br/>" +
                           "Build Number: ${env.BUILD_NUMBER}<br/>" +
                           "URL: ${env.BUILD_URL}<br/>",
                     to: 'Rayane.khadraoui@devoteam.com',
                     attachmentsPattern: 'trivyfs.txt,trivyimage.txt'
        }
    }
}


