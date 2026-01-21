pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: python
    image: python:3.14
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
        //This Stage: Unit Tests is passing
        stage('Unit Tests') {
            steps {
                container('python') {
                    sh '''
                        cd $WORKSPACE

                        # Ensure CA certificates
                        apt-get update && apt-get install -y ca-certificates

                        # Create and activate virtual environment
                        python3 -m venv .venv
                        . .venv/bin/activate

                        # Use system CA certificates
                        export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
                        export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

                        # Upgrade pip
                        pip install --upgrade pip

                        # Install requirements if present
                        if [ -f requirements.txt ]; then
                            pip install -r requirements.txt
                        else
                            echo "No requirements.txt found, skipping pip install"
                        fi
                    '''
                }
            }
        }
        //This Stage: Terraform Validate is passing
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
        //This stage is failing :(
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
                    cd $WORKSPACE || exit 0
                    rm -rf .venv
                    python3 -m venv .venv
                    . .venv/bin/activate
                    echo "Cleanup and venv reset complete."
                '''
            }
        }
    }
}
