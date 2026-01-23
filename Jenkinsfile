pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: "agent"

spec:
  serviceAccountName: jenkins
  dnsPolicy: ClusterFirst
  dnsConfig:
    nameservers:
      - 10.152.183.10

  securityContext:
    sysctls:
      - name: net.ipv6.conf.all.disable_ipv6
        value: "1"
      - name: net.ipv6.conf.default.disable_ipv6
        value: "1"

  containers:
    - name: jnlp
      image: jenkins/inbound-agent:latest
      args:
        - "\$(JENKINS_SECRET)"
        - "\$(JENKINS_NAME)"
      tty: true

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

    stages {

        stage('Unit Tests') {
            steps {
                container('python') {
                    sh '''
                        python3 -m venv .venv
                        . .venv/bin/activate

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
