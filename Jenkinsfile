pipeline {
  agent any

  environment {
    IMAGE_REPO = "hesxo/mi-config"
    IMAGE_TAG = "${env.BUILD_NUMBER}"
    IMAGE = "${IMAGE_REPO}:${IMAGE_TAG}"
    MANIFESTS_REPO = "https://github.com/hesxo/mi-manifests.git"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t $IMAGE .'
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
          echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
          docker push $IMAGE
          '''
        }
      }
    }

    stage('Run Integration Tests') {
      steps {
        sh './scripts/run-newman.sh'
      }
    }

    stage('Update GitOps Repo') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'github-creds', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
          sh '''
          rm -rf /tmp/mi-manifests
          git clone https://${GIT_USER}:${GIT_PASS}@github.com/hesxo/mi-manifests.git /tmp/mi-manifests

          cd /tmp/mi-manifests

          sed -i "s|image: hesxo/mi-config:.*|image: ${IMAGE}|g" base/deployment.yaml

          git config user.name "Jenkins"
          git config user.email "jenkins@local"

          git add base/deployment.yaml
          git commit -m "Update MI image to ${IMAGE}" || true
          git push origin main
          '''
        }
      }
    }

  }
}
