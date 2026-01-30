pipeline {
    agent none

    stages {

        stage('Unit Tests') {
            agent {
                kubernetes {
                    yamlFile 'jenkins/pod-templates/python.yaml' // use pre-built Python container
                }
            }
            steps {
                container('python') {
                    sh '''
                        python3 -m venv .venv
                        . .venv/bin/activate
                        # Run the unit tests (e.g., pytest)
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
                    yamlFile 'jenkins/pod-templates/deploy.yaml' // Use pre-built container for deploy
                }
            }

            environment {
                DOCKER_HOST = 'tcp://localhost:2375'  // Docker-in-Docker (DinD)
            }

            steps {
                container('deploy-container') {
                    sh '''
                        # Deploy with Helm (no build, just deploy)
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
