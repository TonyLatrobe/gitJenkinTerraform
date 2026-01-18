pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: python
    image: python:3.11-slim
    command:
    - cat
    tty: true
"""
    }
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Unit Tests') {
      steps {
        container('python') {
          sh '''
            cd app
            python3 --version
            python3 -m venv .venv
            . .venv/bin/activate
            pip install --upgrade pip
            pip install -r requirements.txt
            pytest
          '''
        }
      }
    }

    stage('Terraform Validate') {
      steps {
        sh '''
          terraform init
          terraform validate
        '''
      }
    }

    stage('Terraform Security') {
      steps {
        sh '''
          tfsec terraform/
          checkov -d terraform/
        '''
      }
    }

    stage('Policy as Code') {
      steps {
        sh '''
          conftest test terraform/ --policy policies/opa
        '''
      }
    }

    stage('Build Image') {
      steps {
        sh 'docker build -t myapp:${BUILD_NUMBER} app/'
      }
    }

    stage('Container Security') {
      steps {
        sh 'trivy image myapp:${BUILD_NUMBER}'
      }
    }

    stage('Deploy') {
      steps {
        sh '''
          helm upgrade --install myapp helm/myapp \
          --set image.tag=${BUILD_NUMBER}
        '''
      }
    }
  }
}
