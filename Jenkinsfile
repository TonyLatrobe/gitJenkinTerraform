pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  dnsPolicy: None
  dnsConfig:
    nameservers:
      - 8.8.8.8
      - 1.1.1.1
  containers:
  - name: python
    image: python:3.12-slim-bullseye
    command: ["cat"]
    tty: true
    stdin: true
  - name: terraform
    image: hashicorp/terraform:1.6.8
    command: ["cat"]
    tty: true
    stdin: true
  - name: security-tools
    image: bridgecrew/checkov:2.0.168
    command: ["cat"]
    tty: true
    stdin: true
  - name: deploy-tools
    image: alpine/helm:3.14.3
    command: ["cat"]
    tty: true
    stdin: true
'''
        }
    }

    stages {
        stage('Unit Tests') {
            steps {
                container('python') {
                    sh '''
                        ip link set dev eth0 mtu 1300 || echo "Could not change MTU, proceeding..."
                        python3 -m venv .venv
                        . .venv/bin/activate
                        pip install --upgrade pip \
                            --timeout 30 \
                            --retries 3 \
                            --trusted-host pypi.org \
                            --trusted-host files.pythonhosted.org \
                            --trusted-host pypi.python.org
                        if [ -f requirements.txt ]; then
                            pip install -r requirements.txt \
                                --trusted-host pypi.org \
                                --trusted-host files.pythonhosted.org \
                                --trusted-host pypi.python.org
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
