pipeline {
  agent any

  environment {
    IMAGE_REPO = "hesxo/mi-config"
    IMAGE_TAG = "${env.GIT_COMMIT.take(7)}"
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

    stage('Prepare Newman Environment') {
      steps {
        sh '''
          cat > integration/newman/environment.json <<EOF2
          {
            "id": "7832d106-1ac6-490b-ac20-87a8d60a1bac",
            "name": "MI Cluster Test",
            "values": [
              {
                "key": "baseUrl",
                "value": "http://host.docker.internal:8290",
                "type": "default",
                "enabled": true
              }
            ],
            "color": null,
            "_postman_variable_scope": "environment",
            "_postman_exported_at": "2026-03-14T08:38:09.099Z",
            "_postman_exported_using": "Postman/12.1.4"
          }
EOF2
        '''
      }
    }

    stage('Run Integration Tests') {
      steps {
        sh '''
          echo "Checking MI endpoint before Newman..."

          for i in $(seq 1 12); do
            if curl -sf http://host.docker.internal:8290/hello/ > /dev/null; then
              echo "MI endpoint is ready"
              ./scripts/run-newman.sh
              exit 0
            fi

            echo "Endpoint not ready... attempt $i"
            sleep 5
          done

          echo "MI endpoint did not become ready in time"
          exit 1
        '''
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