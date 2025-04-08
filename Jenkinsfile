pipeline {
    agent any

    environment {
        // GITHUB_TOKEN = credentials('github-token')
    }

    stages {
        stage('Clone') {
            steps {
                git url: 'https://github.com/rookieboba/fastapi-backend-practice.git', branch: 'main'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t fastapi-backend-practice-web .'
            }
        }

        stage('Run Container') {
            steps {
                sh 'docker stop fastapi-dev || true && docker rm fastapi-dev || true'
                sh 'docker run -d -p 8000:8000 --name fastapi-dev fastapi-backend-practice-web'
            }
        }
    }
}
