pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "adkbhoje/animal-tracker:latest"
        DOCKER_REGISTRY = "adkbhoje"
        IMAGE_NAME = "animal-tracker"
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/adkbhoje/repo.git'  // Your Git repository
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh '''
                    docker build -t ${DOCKER_IMAGE} .
                    '''
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    sh '''
                    docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
                    docker push ${DOCKER_IMAGE}
                    '''
                }
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                script {
                    sh '''
                    terraform -chdir=terraform init
                    terraform -chdir=terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Fetch EC2 Instance IP') {
            steps {
                script {
                    // Fetch the EC2 instance IP from Terraform output
                    INSTANCE_IP = sh(script: "terraform -chdir=terraform output -raw instance_ip", returnStdout: true).trim()

                    // Fetch the private key from Terraform output securely
                    PRIVATE_KEY = sh(script: "terraform -chdir=terraform output -raw private_key", returnStdout: true).trim()

                    // Write the private key to a temporary file with secure permissions
                    writeFile file: '/tmp/my_terraform_key', text: PRIVATE_KEY
                    sh "chmod 600 /tmp/my_terraform_key"  // Ensure the private key is secure

                    // Write the Ansible inventory with the correct private key and instance IP
                    writeFile file: 'ansible/inventory', text: "[app_server]\n${INSTANCE_IP} ansible_ssh_user=ubuntu ansible_ssh_private_key_file=/tmp/my_terraform_key"
                }
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                script {
                    // Running the Ansible playbook using the inventory containing the private key
                    sh 'ansible-playbook -i ansible/inventory ansible/playbook.yml'
                }
            }
        }

        stage('Test Application') {
            steps {
                script {
                    // Test the application by hitting the EC2 instance's public IP
                    sh "curl http://${INSTANCE_IP}"
                }
            }
        }
    }

    post {
        always {
            // Clean up temporary private key file to avoid leaving sensitive data around
            sh 'rm -f /tmp/my_terraform_key'
        }
    }
}