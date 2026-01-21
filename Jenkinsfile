pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: python 
    image: python:3.11 
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
        stage('Unit Tests') {
            steps {
                container('python') {
                    sh '''
                    # Navigate to app directory and clear previous attempts
                    cd app
                    rm -rf .venv

                    python3 -m venv .venv
                    . .venv/bin/activate

                    pip install --upgrade pip \
                    --index-url http://pypi.org/simple \
                    --trusted-host pypi.org

                    pip install -r requirements.txt \
                    --index-url http://pypi.org/simple \
                    --extra-index-url http://files.pythonhosted.org/simple \
                    --trusted-host pypi.org \
                    --trusted-host files.pythonhosted.org

                    # Run tests
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
                    '''
                }
            }
        }

        stage('Build Image') {
            steps {
                // In 2026, building images inside K8s usually requires Kaniko or mounting the socket
                echo "Building Docker image ${DOCKER_IMAGE}:${BUILD_NUMBER}..."
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
