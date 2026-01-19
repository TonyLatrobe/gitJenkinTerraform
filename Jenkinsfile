pipeline {
  agent {
    kubernetes {
      label 'pipetest-agent'
      defaultContainer 'python'
      yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: python
    image: python:3.11-slim
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
  - name: terraform
    image: hashicorp/terraform:1.7.6
    command:
    - cat
    tty: true
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
  restartPolicy: Never
"""
    }
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Python Unit Tests') {
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

    stage('Terraform Plan') {
      steps {
        container('terraform') {
          sh '''
            terraform plan -out=tfplan
          '''
        }
      }
    }
  }

  post {
    always {
      echo "Cleaning up workspace"
      cleanWs()
    }
    success {
      echo "Pipeline completed successfully!"
    }
    failure {
      echo "Pipeline failed."
    }
  }
}
