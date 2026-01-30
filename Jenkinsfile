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
                        # Run the unit tests (e.g., pytest)
                        pytest
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
                    sh '''
                        python3 -m venv .venv
                        . .venv/bin/activate
                        # Run the build (e.g., install dependencies, etc.)
                    '''
                }
            }
        }

        stage('Test') {
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
                        # Run tests after the build (e.g., pytest)
                        pytest --maxfail=1 --disable-warnings -q
                    '''
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
                    // Simply run the necessary deployment tasks inside the container
                    sh 'echo "Deployment container is running"'
                    
                    // You can add any further steps here if required
                    sh '''
                        python3 -m venv .venv
                        . .venv/bin/activate
                        # Install dependencies if needed
                        #pip install -r ${PYTHON_APP_PATH}/requirements.txt
                        # Run the app or a specific deployment command
                        python3 src/app.py
                    '''
                }
            }
        }
        
        stage('Cleanup') {
            agent {
                kubernetes {
                    yamlFile 'jenkins/pod-templates/python.yaml'
                }
            }
            steps {
                container('python') {
                    sh '''
                        # Cleanup code or post-deployment tasks
                    '''
                }
            }
        }
    }
}
