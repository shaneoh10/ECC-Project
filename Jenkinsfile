pipeline {
    agent any

    environment {
        DOCKER_BUILDKIT = '1'
        COMPOSE_DOCKER_CLI_BUILD = '1'
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')  // Match credentials ID exactly
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_REGION = 'us-east-1'  // Replace with your default region, if not a credential
        POSTGRES_DB = credentials('POSTGRES_DB')
        POSTGRES_USER = credentials('POSTGRES_USER')
        POSTGRES_PASSWORD = credentials('POSTGRES_PASSWORD')
        POSTGRES_HOST = credentials('POSTGRES_HOST')
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
                    pip install pre-commit
                    pre-commit run --all-files
                '''
            }
        }

        stage('Build and Test') {
            steps {
                script {
                    // Passing env variables directly for `docker compose` command
                    withEnv([
                        "POSTGRES_DB=${env.POSTGRES_DB}",
                        "POSTGRES_USER=${env.POSTGRES_USER}",
                        "POSTGRES_PASSWORD=${env.POSTGRES_PASSWORD}",
                        "POSTGRES_HOST=${env.POSTGRES_HOST}"
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

        stage('Terraform') {
            steps {
                dir('terraform') {
                    withEnv([
                        "TF_VAR_postgres_db=${env.POSTGRES_DB}",
                        "TF_VAR_postgres_user=${env.POSTGRES_USER}",
                        "TF_VAR_postgres_password=${env.POSTGRES_PASSWORD}",
                        "TF_VAR_postgres_host=${env.POSTGRES_HOST}"
                    ]) {
                        sh '''
                            terraform fmt -check
                            terraform init
                            terraform plan -no-color -out=terraform.tfplan
                        '''
                    }
                }
            }
        }
    }
}
