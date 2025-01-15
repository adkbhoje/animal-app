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
                    withCredentials([usernamePassword(credentialsId: '704020f8-db07-410a-91ca-833bf6c1a86e', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
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
                    withCredentials([aws(credentialsId: 'ce325f53-6263-4a49-9b06-f5241698f237', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh '''
                        terraform -chdir=terraform init
                        terraform -chdir=terraform apply -auto-approve
                        '''
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
                    sh "curl http://${INSTANCE_IP}"
                }
            }
        }
    }

    post {
        always {
            // Clean up the private key
            sh 'rm -f /tmp/my_terraform_key'
        }
    }
}
