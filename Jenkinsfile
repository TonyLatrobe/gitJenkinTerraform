pipeline {
  agent none

  stages {

    stage('Unit Tests') {
      agent {
        kubernetes {
          yamlFile 'jenkins/pod-templates/deploy.yaml' // must have DinD container
          defaultContainer 'dind'
          yamlMergeStrategy 'merge'
          // OPTION 1: use host networking for DinD
          hostNetwork true
        }
      }
      steps {
        container('dind') {
          sh '''
            # Start Docker daemon
            dockerd-entrypoint.sh &

            # Wait for Docker daemon to be ready
            timeout 30 sh -c "until docker info >/dev/null 2>&1; do sleep 1; done"

            # Build the Python image locally
            docker build -t myapp:python -f docker/Dockerfile.python ./app

            # Run unit tests inside the container
            docker run --rm myapp:python pytest tests/
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
          sh '''
            set +e
            checkov -d . -o json > checkov.json

            TOTAL=$(jq '.summary.total_checks' checkov.json)
            FAILED=$(jq '.summary.failed' checkov.json)

            if [ "$TOTAL" -eq 0 ]; then
              echo "No checks found – passing"
              exit 0
            fi

            FAILURE_RATE=$(awk "BEGIN {print ($FAILED/$TOTAL)*100}")

            echo "Checkov failure rate: ${FAILURE_RATE}%"

            if (( $(echo "$FAILURE_RATE > 10" | bc -l) )); then
              echo "❌ Failure rate exceeds 10%"
              exit 1
            else
              echo "✅ Failure rate within 10% threshold"
              exit 0
            fi
          '''
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
          defaultContainer 'dind'
          yamlMergeStrategy 'merge'
          hostNetwork true  // OPTION 1 applied here too
        }
      }

      environment {
        HELM_CACHE_HOME  = '/tmp/helm/cache'
        HELM_CONFIG_HOME = '/tmp/helm/config'
        HELM_DATA_HOME   = '/tmp/helm/data'
        DOCKER_HOST      = 'tcp://localhost:2375'  // DinD daemon
      }

      steps {
        container('dind') {
          sh '''
            # Start Docker daemon
            dockerd-entrypoint.sh &

            # Wait for Docker daemon to be ready
            timeout 30 sh -c "until docker info >/dev/null 2>&1; do sleep 1; done"

            # Build image
            docker build -t localhost:32000/myapp:${BUILD_NUMBER}-patched -f docker/Dockerfile.python ./app

            # Push to MicroK8s registry
            docker push localhost:32000/myapp:${BUILD_NUMBER}-patched

            # Deploy with Helm
            helm upgrade --install myapp ${WORKSPACE}/helm/myapp \
              --set image.repository=localhost:32000/myapp \
              --set image.tag=${BUILD_NUMBER}-patched \
              --set image.pullPolicy=IfNotPresent
          '''
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
