pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: python
    image: python:3.11-slim
    command: ["cat"]
    tty: true
  - name: terraform
    image: hashicorp/terraform:latest
    command: ["cat"]
    tty: true
  - name: security-tools
    image: bridgecrew/checkov:latest
    command: ["cat"]
    tty: true
  - name: deploy-tools
    image: alpine/helm:latest
    command: ["cat"]
    tty: true
'''
        }
    }

    environment {
        DOCKER_IMAGE = 'myapp'
    }

    stages {
        // Removed Setup CA Cert as per your request

        stage('Unit Tests') {
            steps {
                container('python') {
                    sh '''
                    cd app
                    python3 -m venv .venv
                    . .venv/bin/activate
                    pip install -r requirements.txt
                    pytest
                    '''
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                container('terraform') {
                    sh '''
                    terraform init
                    terraform validate
                    '''
                }
            }
        }

        stage('Terraform Security') {
            steps {
                container('security-tools') {
                    sh '''
                    checkov -d .
                    # tfsec is also available in many security bundles
                    '''
                }
            }
        }

        // Note: For 'Build Image' in 2026 Kubernetes, you should ideally use Kaniko. 
        // Using 'docker build' requires mounting the host docker socket.
        stage('Build Image') {
            steps {
                echo "In 2026, use Kaniko here to build images without Docker-in-Docker"
                // container('kaniko') { ... }
            }
        }

        stage('Deploy') {
            steps {
                container('deploy-tools') {
                    sh '''
                    helm upgrade --install myapp helm/myapp \
                      --set image.tag=${BUILD_NUMBER}
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
