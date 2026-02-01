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
                        # Run the unit tests
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
                        # Build / install dependencies
                        # e.g., python -m pip install -r requirements.txt
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
                        # Run tests after the build
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
                    dir('app') {
                        sh '''
                            python3 -m venv .venv
                            . .venv/bin/activate
                            python3 -m src.app 3 5
                        '''
                    }
                }
            }
        }
    } // end stages
} // end pipeline
