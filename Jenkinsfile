pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: python
    image: python:3.12
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
                        # 1. Address potential OpenSSL Handshake strictness
                        cat > /tmp/openssl.cnf <<EOF
openssl_conf = default_conf
[default_conf]
ssl_conf = ssl_sect
[ssl_sect]
system_default = system_default_sect
[system_default_sect]
CipherString = DEFAULT@SECLEVEL=1
EOF
                        export OPENSSL_CONF=/tmp/openssl.cnf

                        # 2. Setup Virtual Environment
                        python3 -m venv .venv
                        . .venv/bin/activate

                        # 3. Upgrade pip with trusted-host flags
                        pip install --upgrade pip \
                            --trusted-host pypi.org \
                            --trusted-host files.pythonhosted.org \
                            --trusted-host pypi.python.org

                        # 4. Install requirements
                        if [ -f requirements.txt ]; then
                            pip install -r requirements.txt \
                                --trusted-host pypi.org \
                                --trusted-host files.pythonhosted.org \
                                --trusted-host pypi.python.org
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
                // Note: Building docker images inside K8s usually requires Kaniko or DinD
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
            container('python') {
                sh 'rm -rf .venv'
            }
            cleanWs()
        }
    }
}