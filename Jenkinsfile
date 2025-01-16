pipeline {
    agent any

    environment {
        PATH = "/usr/local/bin:$PATH"
        DOCKER_IMAGE = "adkbhoje/animal-tracker:latest"
        DOCKER_REGISTRY = "adkbhoje"
        IMAGE_NAME = "animal-tracker"
        TF_LOG = "DEBUG" // Enable detailed Terraform logging
        TF_LOG_PATH = "terraform-debug.log" // Log output for Terraform
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    git branch: 'main', url: 'https://github.com/adkbhoje/animal-app', credentialsId: 'github-token'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh '''
                    docker build -t ${DOCKER_IMAGE} -f docker/Dockerfile .
                    '''
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh '''
                        docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
                        docker push ${DOCKER_IMAGE}
                        '''
                    }
                }
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                script {
                    withCredentials([aws(credentialsId: 'aws-credentials', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        timeout(time: 15, unit: 'MINUTES') { // Increased timeout to handle delays
                            withEnv(["TF_LOG=DEBUG", "TF_LOG_PATH=terraform-debug.log"]) {
                                dir('terraform') {
                                    sh '''
                                    echo "Initializing Terraform..."
                                    terraform init

                                    echo "Validating Terraform configuration..."
                                    terraform validate

                                    echo "Applying Terraform changes..."
                                    terraform apply -auto-approve
                                    '''
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Fetch EC2 Instance IP') {
            steps {
                script {
                    INSTANCE_IP = sh(script: "terraform -chdir=terraform output -raw instance_ip", returnStdout: true).trim()

                    // Fetch private key securely
                    PRIVATE_KEY = sh(script: "terraform -chdir=terraform output -raw private_key", returnStdout: true).trim()
                    writeFile file: '/tmp/my_terraform_key', text: PRIVATE_KEY
                    sh "chmod 600 /tmp/my_terraform_key"

                    // Write Ansible inventory
                    writeFile file: 'ansible/inventory', text: "[app_server]\n${INSTANCE_IP} ansible_ssh_user=ubuntu ansible_ssh_private_key_file=/tmp/my_terraform_key"
                }
            }
        }

        stage('Run Ansible Playbook') {
            steps {
                sh 'ansible-playbook -i ansible/inventory ansible/playbook.yml'
            }
        }

        stage('Test Application') {
            steps {
                script {
                    sh "curl -f http://${INSTANCE_IP}"
                }
            }
        }
    }

    post {
        always {
            script {
                // Cleanup private key and Terraform processes
                sh '''
                rm -f /tmp/my_terraform_key
                pkill -f terraform-provider-aws || true
                '''
            }
        }
        success {
            echo "Pipeline executed successfully!"
        }
        failure {
            echo "Pipeline failed. Check logs for errors."
        }
    }
}
