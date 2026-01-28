pipeline {
  agent none

  stages {

    stage('Unit Tests') {
      agent {
        kubernetes {
          yamlFile 'jenkins/pod-templates/python.yaml'
        }
      }
      steps {
        container('python') {
          sh '''
            python3 -m venv .venv
            . .venv/bin/activate
          '''
        }
      }
      post {
        always {
          deleteDir()
        }
      }
    }

    stage('Terraform Validate') {
      agent {
        kubernetes {
          yamlFile 'jenkins/pod-templates/terraform.yaml'
        }
      }
      steps {
        container('terraform') {
          sh 'terraform init && terraform validate'
        }
      }
      post {
        always {
          deleteDir()
        }
      }
    }

    stage('Terraform Security') {
      agent {
        kubernetes {
          yamlFile 'jenkins/pod-templates/security.yaml'
        }
      }
      steps {
        container('security-tools') {
          sh 'checkov -d .'
        }
      }
      post {
        always {
          deleteDir()
        }
      }
    }

    stage('Deploy') {
      agent {
        kubernetes {
          yamlFile 'jenkins/pod-templates/deploy.yaml'
        }
      }
      steps {
        container('deploy-tools') {
          sh "helm upgrade --install myapp helm/myapp --set image.tag=${BUILD_NUMBER}"
        }
      }
      post {
        always {
          deleteDir()
        }
      }
    }
  }
}
