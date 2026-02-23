pipeline {
    agent {
        kubernetes { // force to use the same pod/container for all stages (instead of creating them at each stage)
            yamlFile 'jenkins/pod-templates/devops.yaml'
            defaultContainer 'ci'
        }
    }

    stages {
        stage('Debug') {
            steps {
                echo "Debug stage - placeholder"
            }
        }

        stage('Unit Tests') {
            steps {
                sh '''
                    echo "Container hostname:"
                    hostname
                    echo "PATH=$PATH"
                    which pytest || true
                '''

                sh '''
                    # Run tests directly — no need to create venv
                    pytest app/
                '''
            }
        }

        stage('Build') {
            steps {
                sh 'echo "Build step - nothing to do"'
            }
        }

        stage('Terraform Validate') {
            steps {
                sh '''
                    cd terraform
                    terraform init
                    terraform validate
                '''
            }
        }

        stage('Terraform Security') {
            steps {
                sh '''
                    set +e
                    checkov -d . -o json > checkov.json

                    # FIX: Checkov JSON is an array, so index [0]
                    TOTAL=$(jq '.[0].summary.total_checks' checkov.json)
                    FAILED=$(jq '.[0].summary.failed' checkov.json)

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

        stage('Deploy') {
            steps {
                // FIX: Ensure Deploy runs in the same container as pytest
                container('ci') {
                sh ''' 
                echo "Workspace contents:"
                ls -R .
                echo "Searching for app.py:"
                find . -maxdepth 4 -type f -name app.py -print 
                # Run the module from the workspace root 
                python -m app.src.app 3 5 '''
                }
            }
        }
    }
}
