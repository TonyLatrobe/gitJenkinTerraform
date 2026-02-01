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
                    sh '''
                        # Already installed dependencies in Docker
                        echo "Build step - nothing to do"
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
                        pytest --maxfail=1 --disable-warnings -q app/
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
                    dir('app') {
                        sh 'python -m src.app 3 5'
                    }
                }
            }
        }
    }
}
