pipeline {
  agent any

  environment {
    IMAGE = "hesxo/mi-config:0.1.0"
    MANIFESTS_REPO = "https://github.com/hesxo/mi-manifests.git"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Image') {
      steps {
        sh 'docker build -t $IMAGE .'
      }
    }

    stage('Run Integration Tests') {
      steps {
        sh './scripts/run-newman.sh'
      }
    }

    stage('Show Manifests Repo') {
      steps {
        sh 'echo "Next later: update mi-manifests repo automatically after tests pass"'
      }
    }
  }
}
