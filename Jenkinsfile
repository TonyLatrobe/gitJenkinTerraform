pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: python
    image: python:3.13-slim
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
                        python3 -m venv .venv
                        . .venv/bin/activate

                        export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
                        export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

                        pip install --upgrade pip

                        if [ -f requirements.txt ]; then
                            pip install -r requirements.txt
                        else
                            echo "No requirements.txt found, skipping pip install"
                        fi
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
                    sh 'checkov -d .'
                }
            }
        }

        stage('Build Image') {
            steps {
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
            container('python') {
                sh '''
                    rm -rf .venv
                '''
            }
            cleanWs()
        }
    }
}
