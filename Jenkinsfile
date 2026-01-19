pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
    - name: python
      image: python:3.11-slim
      command: ["cat"]
      tty: true
      volumeMounts:
        - name: jenkins-ca
          mountPath: /etc/ssl/certs/jenkins-ca
          readOnly: true

    - name: jnlp
      image: jenkins/inbound-agent:3355.v388858a_47b_33-2-jdk21
      volumeMounts:
        - name: jenkins-ca
          mountPath: /etc/ssl/certs/jenkins-ca
          readOnly: true

  volumes:
    - name: jenkins-ca
      configMap:
        name: jenkins-ca-cert
"""
        }
    }

    environment {
        PYTHON_IMAGE = 'python:3.11-slim'
        DOCKER_IMAGE = 'myapp'
    }

    stages {

        stage('Checkout') {
            steps {
                git url: 'https://github.com/TonyLatrobe/gitJenkinTerraform'
            }
        }

        stage('Setup CA Cert') {
            steps {
                container('python') {
                    sh '''
                    set -e
                    echo "Installing MicroK8s CA cert..."

                    # Copy the ConfigMap-mounted cert to system CA location
                    cp /etc/ssl/certs/jenkins-ca/ca.crt /usr/local/share/ca-certificates/jenkins-ca.crt
                    update-ca-certificates

                    # Also import into Java keystore for Jenkins agent
                    JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
                    keytool -importcert -trustcacerts -file /etc/ssl/certs/jenkins-ca/ca.crt -alias microk8s-ca \
                        -keystore $JAVA_HOME/lib/security/cacerts -storepass changeit -noprompt || true
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
                container('python') {
                    sh '''
                    terraform init
                    terraform validate
                    '''
                }
            }
        }

        stage('Terraform Security') {
            steps {
                container('python') {
                    sh '''
                    tfsec terraform/
                    checkov -d terraform/
                    '''
                }
            }
        }

        stage('Policy as Code') {
            steps {
                container('python') {
                    sh '''
                    conftest test terraform/ --policy policies/opa
                    '''
                }
            }
        }

        stage('Build Image') {
            steps {
                container('python') {
                    sh 'docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} app/'
                }
            }
        }

        stage('Container Security') {
            steps {
                container('python') {
                    sh 'trivy image ${DOCKER_IMAGE}:${BUILD_NUMBER}'
                }
            }
        }

        stage('Deploy') {
            steps {
                container('python') {
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
