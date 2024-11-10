pipeline {
    agent any
    environment {
        DOCKER_BUILDKIT = '1'
        COMPOSE_DOCKER_CLI_BUILD = '1'
        // Set pre-commit cache to a writable temp directory
        PRE_COMMIT_HOME = '/tmp/.pre-commit-cache'
    }
    options {
        disableConcurrentBuilds()
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Linting') {
            agent {
                docker {
                    image 'python:3.12'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    # Create cache directory with correct permissions
                    mkdir -p ${PRE_COMMIT_HOME}
                    
                    # Create and activate virtual environment
                    python -m venv .venv
                    . .venv/bin/activate
                    
                    # Install and run pre-commit
                    pip install pre-commit
                    pre-commit run --all-files
                    
                    # Deactivate virtual environment
                    deactivate
                '''
                
                // Clean up virtual environment and cache
                cleanWs patterns: [
                    [pattern: '.venv/**', type: 'INCLUDE'],
                    [pattern: '.pre-commit-cache/**', type: 'INCLUDE']
                ]
            }
        }
        stage('Build and Test') {
            steps {
                script {
                    withEnv([
                        "POSTGRES_DB=${params.POSTGRES_DB}",
                        "POSTGRES_USER=${params.POSTGRES_USER}",
                        "POSTGRES_PASSWORD=${params.POSTGRES_PASSWORD}",
                        "POSTGRES_HOST=${params.POSTGRES_HOST}"
                    ]) {
                        sh 'docker compose -f docker-compose.local.yml build django'
                        sh 'docker compose -f docker-compose.docs.yml build docs'
                        sh 'docker compose -f docker-compose.local.yml run --rm django python manage.py makemigrations --check'
                        sh 'docker compose -f docker-compose.local.yml run --rm django python manage.py migrate'
                        sh 'docker compose -f docker-compose.local.yml run django pytest'
                    }
                }
            }
            post {
                always {
                    sh 'docker compose -f docker-compose.local.yml down'
                }
            }
        }
    }
}