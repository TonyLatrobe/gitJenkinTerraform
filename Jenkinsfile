pipeline {
    agent none

    stages {
        stage('Debug') {
            steps {
                echo "Debug stage - placeholder"
            }
        }

        stage('Unit Tests') {
            agent {
                kubernetes {
                    yamlFile 'jenkins/pod-templates/python.yaml'
                }
            }
            steps {
                container('python') {
                    sh '''
                        # Run tests directly — no need to create venv
                        pytest app/
                    '''
                }
            }
        }

        stage('Build') {
            agent {
                kubernetes {
                    yamlFile 'jenkins/pod-templates/python.yaml'
                }
            }
            steps {
                container('python') {
                    sh 'echo "Build step - nothing to do"'
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
                    sh '''
                    cd terraform
                    terraform init
                    terraform validate
                    '''
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
                }
            }
            steps {
                container('deploy-container') {
                    dir('app') {
                        sh 'python -m src.app 3 5'
                    }
                }
            }
        }
    }
}
