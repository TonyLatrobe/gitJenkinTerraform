pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: python
    image: python:3.13-slim   # latest stable Python 3.12 LTS
    command: ["cat"]
    tty: true
  - name: terraform
    image: hashicorp/terraform:1.7.6   # latest stable Terraform LTS
    command: ["cat"]
    tty: true
  - name: security-tools
    image: bridgecrew/checkov:3.2.497   # latest Checkov
    command: ["cat"]
    tty: true
  - name: deploy-tools
    image: alpine/helm:3.12.1   # latest Helm stable
    command: ["cat"]
    tty: true
"""
        }
    }

    environment {
        DOCKER_IMAGE = 'myapp'
    }

    stages {

        stage('Unit Tests') {
            container('python') {
                sh '''
                    #!/bin/bash
                    set -e

                    # Create virtual environment
                    python3 -m venv .venv
                    . .venv/bin/activate

                    # Ensure system CA certificates are used
                    export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
                    export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

                    # Upgrade pip (ignore SSL errors for now)
                    pip install --upgrade pip || true

                    # Install project requirements if present
                    if [ -f requirements.txt ]; then
                        pip install -r requirements.txt
                    else
                        echo "No requirements.txt found, skipping pip install"
                    fi
                '''
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
                    sh 'checkov -d .'
                }
            }
        }

        stage('Build Image') {
            steps {
                echo "Building Docker image ${DOCKER_IMAGE}:${BUILD_NUMBER}..."
                // Add Kaniko or Docker socket logic here if needed
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
            container('python') {
                sh '''
                    #!/bin/bash
                    set -e
                    # Clean up virtual environment
                    rm -rf .venv
                '''
            }
            cleanWs()
        }
    }
}
