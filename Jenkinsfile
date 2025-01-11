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
                    INSTANCE_IP = sh(script: "terraform -chdir=terraform output -raw instance_ip", returnStdout: true).trim()
                    writeFile file: 'ansible/inventory', text: "[app_server]\n${INSTANCE_IP} ansible_ssh_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa"
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
}