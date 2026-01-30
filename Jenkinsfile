pipeline {
    agent none
    environment {
        REGISTRY = 'localhost:32000'  // MicroK8s registry
        IMAGE_NAME = 'myapp'  // The image name
    }
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
                    script {
                        def buildTag = "${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}-patched"
                        echo "Deploying image with tag: ${buildTag}"

                        // Pull the image from the MicroK8s registry (make sure it's available)
                        sh """
                            docker pull ${buildTag}
                        """

                        // Deploy using kubectl, updating the deployment with the image from the registry
                        sh """
                            kubectl set image deployment/myapp myapp=${buildTag}
                        """
                    }
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
