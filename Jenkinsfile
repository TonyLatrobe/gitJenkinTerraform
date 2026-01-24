pipeline {
  agent {
    kubernetes {
      yamlFile 'jenkins/pod-templates/ci-python.yaml'
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
            [ -f requirements.txt ] && pip install -r requirements.txt
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
