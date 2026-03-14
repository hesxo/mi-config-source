pipeline {
  agent any

  environment {
    IMAGE_REPO = "hesxo/mi-config"
    IMAGE_TAG = "${env.GIT_COMMIT.take(7)}"
    IMAGE = "${IMAGE_REPO}:${IMAGE_TAG}"
    TEST_CONTAINER = "mi-test-${env.BUILD_NUMBER}"
    TEST_PORT = "18290"
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

    stage('Start Ephemeral Test Container') {
      steps {
        sh '''
          docker rm -f $TEST_CONTAINER || true
          docker run -d --name $TEST_CONTAINER -p ${TEST_PORT}:8290 $IMAGE

          echo "Waiting for MI container to become ready..."
          for i in $(seq 1 18); do
            if curl -sf http://host.docker.internal:${TEST_PORT}/hello/ > /dev/null; then
              echo "MI is ready"
              exit 0
            fi
            echo "Not ready yet... attempt $i"
            sleep 5
          done

          echo "MI failed to become ready in time"
          docker logs $TEST_CONTAINER || true
          exit 1
        '''
      }
    }

    stage('Run Integration Tests') {
      steps {
        sh './scripts/run-newman.sh'
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

  post {
    always {
      sh 'docker rm -f $TEST_CONTAINER || true'
    }
  }
}
