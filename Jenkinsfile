pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: python
    image: ubuntu:22.04
    command: ["cat"]
    tty: true
    securityContext:
      privileged: false 
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

    stages {
        stage('Unit Tests') {
            steps {
                container('python') {
                    sh '''
                        # Update OS and install python3 + pip + common tools
                        apt-get update && apt-get install -y python3 python3-venv python3-pip curl iputils-ping dnsutils

                        # Setup virtual environment
                        python3 -m venv .venv
                        . .venv/bin/activate

                        # Upgrade pip and install requirements
                        pip install --upgrade pip setuptools wheel

                        if [ -f requirements.txt ]; then
                            pip install -r requirements.txt
                        else
                            echo "No requirements.txt found."
                        fi
                    '''
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                container('terraform') {
                    sh 'terraform init && terraform validate'
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

        stage('Deploy') {
            steps {
                container('deploy-tools') {
                    sh "helm upgrade --install myapp helm/myapp --set image.tag=${BUILD_NUMBER}"
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
