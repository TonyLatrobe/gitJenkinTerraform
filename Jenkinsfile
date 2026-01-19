pipeline {
    agent {
        kubernetes {
            inheritFrom 'pipetest-agent'
        }
    }

    environment {
        DOCKER_IMAGE = 'myapp'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup CA Cert') {
            steps {
                container('python') {
                    sh '''
                    echo "Importing Jenkins CA cert..."

                    cp /etc/ssl/certs/jenkins-ca/ca.crt \
                       /usr/local/share/ca-certificates/jenkins-ca.crt

                    update-ca-certificates || true
                    '''
                }
            }
        }

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
                container('security') {
                    sh '''
                    tfsec terraform/
                    checkov -d terraform/
                    '''
                }
            }
        }

        stage('Policy as Code') {
            steps {
                container('security') {
                    sh '''
                    conftest test terraform/ --policy policies/opa
                    '''
                }
            }
        }

        stage('Build Image') {
            steps {
                container('docker') {
                    sh '''
                    docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} app/
                    '''
                }
            }
        }

        stage('Container Security') {
            steps {
                container('security') {
                    sh '''
                    trivy image ${DOCKER_IMAGE}:${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                container('helm') {
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
