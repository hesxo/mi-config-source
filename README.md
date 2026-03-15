# 📦 mi-config-source

<p align="center">
  <strong>Source repository for WSO2 Micro Integrator configurations,<br>
  Newman integration tests, and the Jenkins CI pipeline.</strong>
</p>

<p align="center">
  <a href="#-deployment-flow">Flow</a> •
  <a href="#-tech-stack">Stack</a> •
  <a href="#-build-and-run-locally">Quick start</a> •
  <a href="#-ci-pipeline-jenkins">CI</a> •
  <a href="#-observability--gitops-screenshots">Screenshots</a>
</p>

---

## 📋 Overview

| Item | Value |
|------|-------|
| **Base image** | `wso2/wso2mi:4.5.0` |
| **Docker image** | `hesxo/mi-config` (tagged with short Git commit SHA) |
| **GitOps repo** | [hesxo/mi-manifests](https://github.com/hesxo/mi-manifests) — deployment image is updated on every successful pipeline run |
| **Sample API** | `HelloAPI` — `GET /hello/` on port **8290** → `{"message":"hello from WSO2 MI"}` |

The pipeline builds a custom MI Docker image with baked-in Synapse API definitions and observability config, runs integration tests, pushes the image to Docker Hub, and updates the GitOps manifests repo. **Argo CD** then syncs those manifests to the Kubernetes cluster.

> [!IMPORTANT]
> This repository uses a **GitOps-first** approach. All infrastructure and deployment changes are driven by Git commits to this source repo and the associated [manifests repository](https://github.com/hesxo/mi-manifests).

## 🔧 Tech stack

| Layer | Technology |
|:-------|------------|
| **Runtime** | <img src="https://wso2.cachefly.net/wso2/sites/all/2023/images/webp/wso2-logo.webp" width="16" /> [WSO2 Mi](https://wso2.com/integration/micro-integrator/) 4.5.0 |
| **API Config** | <img src="https://apache.org/images/feather-small.gif" width="16" /> Apache Synapse |
| **Container** | <img src="https://upload.wikimedia.org/wikipedia/commons/8/89/Docker_Logo.svg" width="16" /> Docker |
| **CI/CD** | <img src="https://upload.wikimedia.org/wikipedia/commons/e/e9/Jenkins_logo.svg" width="16" /> Jenkins |
| **Testing** | <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/postman/postman-original.svg" width="16" /> Newman |
| **GitOps** | <img src="https://raw.githubusercontent.com/argoproj/argo-cd/master/docs/assets/logo.png" width="16" /> Argo CD |
| **Monitoring** | <img src="https://grafana.com/static/assets/img/fav32.png" width="16" /> Grafana + Prometheus |

---

## 🏗️ System Architecture

```mermaid
flowchart TD

    %% Source Layer
    A1[📄 Synapse API Configs]
    A2[🐳 Dockerfile]
    A3[🧪 Newman Integration Tests]

    %% Source Repository
    B[📂 GitHub Repository<br/>mi-config-source]

    %% CI
    C[⚙️ Jenkins CI Pipeline]

    %% Container Registry
    D[🐳 Docker Hub<br/>hesxo/mi-config]

    %% GitOps Repository
    E[📦 GitOps Repository<br/>mi-manifests]

    %% CD
    F[🔄 Argo CD]

    %% Cluster
    G[☸️ Kubernetes Cluster]

    %% Runtime
    H[⚡ WSO2 Micro Integrator Pods]

    %% Observability
    I[📡 Prometheus]
    J[📊 Grafana Dashboard]
    K[🚨 Alertmanager]

    %% Flow
    A1 --> B
    A2 --> B
    A3 --> B

    B -->|CI Trigger| C

    C -->|Build & Push Image| D
    C -->|Run Integration Tests| A3

    C -->|Update Deployment Image| E

    E -->|GitOps Sync| F

    F -->|Deploy| G

    G --> H

    H -->|Expose Metrics :9201| I

    I --> J
    I --> K
## 📂 Related repositories

| Repo | Purpose |
|------|---------|
| [**mi-manifests**](https://github.com/hesxo/mi-manifests) | GitOps repo containing Kustomize base (`Deployment`, `Service`, `ServiceMonitor`) + `overlays/prod` and an Argo CD `Application` resource. Jenkins updates the image tag here; Argo CD syncs from here. |

---

## 📁 Repository structure

```
mi-config-source/
├── Dockerfile                        # Builds the MI image with synapse configs + observability
├── Jenkinsfile                       # Declarative CI pipeline
├── conf/
│   └── observability.toml            # Prometheus metrics & synapse handler config (appended to deployment.toml)
├── src/
│   └── synapse-config/
│       └── api/
│           └── HelloAPI.xml          # Sample Synapse API definition
├── integration/
│   └── newman/
│       ├── collection.json           # Postman/Newman test collection
│       └── environment.json          # Newman environment (baseUrl variable)
├── scripts/
│   └── run-newman.sh                 # Executes Newman against the collection + environment
└── k8s-test/                         # (Reserved) Kubernetes test manifests
```

---

## ✅ Prerequisites

| Requirement | Notes |
|-------------|-------|
| **Docker** | Required for building and running the MI image locally |
| **Newman** | *(optional)* For running integration tests locally — `npm install -g newman` |
| **Jenkins** | For CI — needs `dockerhub-creds` and `github-creds` credentials configured |
> [!TIP]
> To run the full CI/CD suite locally, ensure your Docker daemon has at least 4GB of RAM allocated, as WSO2 MI can be resource-intensive during startup.

---

## 🚀 Build and run locally

### 1. Build the Docker image

```bash
docker build -t hesxo/mi-config:local .
```

### 2. Start the MI container

```bash
docker run -p 8290:8290 -p 8253:8253 -p 9164:9164 -p 9201:9201 hesxo/mi-config:local
```

| Port | Service |
|------|---------|
| **8290** | HTTP API passthrough |
| **8253** | HTTPS API passthrough |
| **9164** | Management API |
| **9201** | Prometheus metrics endpoint |

### 3. Test the API

```bash
curl http://localhost:8290/hello/
```

**Expected response:**

```json
{
  "message": "hello from WSO2 MI"
}
```

---

## 📮 Testing with Postman (step-by-step)

<details>
<summary><strong>Click to expand Postman walkthrough</strong></summary>

#### Prerequisites

- Install [Docker](https://www.docker.com/get-started) and [Postman](https://www.postman.com/downloads/).
- Open a terminal in the project root (`mi-config-source/`).

#### Step 1 — Build and run the MI container

```bash
docker build -t hesxo/mi-config:local .
docker run -p 8290:8290 -p 8253:8253 -p 9164:9164 -p 9201:9201 hesxo/mi-config:local
```

Leave the terminal open. Wait until you see *"WSO2 Micro Integrator started"* in the logs.

#### Step 2 — Import the collection

1. In Postman, click **Import** (top left).
2. Select `integration/newman/collection.json`.
3. You should see the collection **"MI Hello API Tests"**.

#### Step 3 — Import the environment

1. Click **Import** again.
2. Select `integration/newman/environment.json`.
3. You should see the environment **"MI Ephemeral Test"**.

#### Step 4 — Set the base URL

1. Click the **Environments** icon (gear) in the left sidebar.
2. Open **MI Ephemeral Test**.
3. Set the **Current Value** of `baseUrl` to `http://localhost:8290`.
4. Click **Save**.

> **Note:** The initial value may be `http://host.docker.internal:18290`; change it for local testing.

#### Step 5 — Send the request

1. In the top-right dropdown, select the **MI Ephemeral Test** environment.
2. Expand **MI Hello API Tests** in the sidebar.
3. Click **GET /hello/** — the URL should resolve to `http://localhost:8290/hello/`.
4. Click **Send**.

#### Step 6 — Verify the response

| Field | Expected |
|-------|----------|
| **Status** | `200 OK` |
| **Body** | `{"message":"hello from WSO2 MI"}` |

</details>

---

## 🧪 Integration tests (Newman)

Tests are defined in `integration/newman/collection.json` and use `integration/newman/environment.json` for the `baseUrl` variable.

**Run locally** (MI must be running on the port specified in `environment.json`):

```bash
./scripts/run-newman.sh
```

**In CI:** The Jenkinsfile overwrites `environment.json` with `baseUrl: http://host.docker.internal:8290`, polls the endpoint until it is ready (up to 12 × 5 s), then invokes `./scripts/run-newman.sh`.

---

## 🔄 CI pipeline (Jenkins)

The declarative pipeline in [`Jenkinsfile`](Jenkinsfile) runs the following stages:

| # | Stage | Description |
|:-:|-------|-------------|
| 1 | **Checkout** | Clone this repository |
| 2 | **Build Docker Image** | `docker build -t $IMAGE .` — tag is the 7-char Git commit SHA |
| 3 | **Push Docker Image** | Push to Docker Hub using `dockerhub-creds` |
| 4 | **Prepare Newman Environment** | Generate `environment.json` with `baseUrl` pointing to `host.docker.internal:8290` |
| 5 | **Run Integration Tests** | Poll `GET /hello/` until ready, then execute Newman |
| 6 | **Update GitOps Repo** | Clone `mi-manifests`, `sed`-replace the image tag in `base/deployment.yaml`, commit & push |

After the push, **Argo CD** detects the manifest change and syncs the new deployment to the cluster.

### Required Jenkins credentials

| Credential ID | Type | Purpose |
|----------------|------|---------|
| `dockerhub-creds` | Username / Password | Push images to Docker Hub |
| `github-creds` | Username / Password (or PAT) | Push manifest updates to `mi-manifests` |

---

## ✏️ Adding or changing APIs

1. Add or edit XML files under `src/synapse-config/api/` (e.g., `HelloAPI.xml`).
2. Rebuild the image locally and run Newman to verify.
3. Commit and push — Jenkins will build, test, and update the GitOps repo automatically.

---

## 📊 Observability & GitOps screenshots

Screenshots below show the end-to-end flow: **Argo CD** deploys from Git, **Jenkins** builds and updates the image, **Grafana** and **Prometheus** provide metrics and alerting, and **Slack** and **Email** deliver notifications.

---

### <img src="https://raw.githubusercontent.com/argoproj/argo-cd/master/docs/assets/logo.png" width="24" alt="" /> Argo CD — GitOps deployment

| |
|:--:|
| **[Argo CD – mi-application](https://i.postimg.cc/T1KKw766/Screenshot-2026-03-14-at-8-38-28-PM.png)** |
| <a href="https://i.postimg.cc/T1KKw766/Screenshot-2026-03-14-at-8-38-28-PM.png"><img src="https://i.postimg.cc/T1KKw766/Screenshot-2026-03-14-at-8-38-28-PM.png" alt="Argo CD Application" width="720" /></a> |

This view shows the `mi-application` Argo CD app that syncs the `mi-manifests` GitOps repo into the `mi-prod` namespace. Health and sync status indicate if the MI deployment, service, and `ServiceMonitor` are up-to-date with Git.

---

### <img src="https://upload.wikimedia.org/wikipedia/commons/e/e9/Jenkins_logo.svg" width="24" alt="" /> Jenkins — CI pipeline

| |
|:--:|
| **[Jenkins pipeline run](https://i.postimg.cc/52SLDr9K/Screenshot-2026-03-14-at-6-36-39-PM.png)** |
| <a href="https://i.postimg.cc/52SLDr9K/Screenshot-2026-03-14-at-6-36-39-PM.png"><img src="https://i.postimg.cc/52SLDr9K/Screenshot-2026-03-14-at-6-36-39-PM.png" alt="Jenkins Pipeline" width="720" /></a> |

The Jenkins declarative pipeline builds the MI Docker image, runs Newman integration tests, and then updates the `mi-manifests` deployment image tag so Argo CD can roll out the new version.

---

### <img src="https://grafana.com/static/assets/img/fav32.png" width="24" alt="" /> Grafana — WSO2 MI dashboard

| |
|:--:|
| **[Grafana MI dashboard](https://i.postimg.cc/QxpTWz7h/Screenshot-2026-03-14-at-8-38-44-PM.png)** |
| <a href="https://i.postimg.cc/QxpTWz7h/Screenshot-2026-03-14-at-8-38-44-PM.png"><img src="https://i.postimg.cc/QxpTWz7h/Screenshot-2026-03-14-at-8-38-44-PM.png" alt="Grafana Dashboard" width="720" /></a> |

Grafana visualizes Prometheus metrics exposed by WSO2 MI, including HTTP/API performance, JVM metrics, and overall health, giving a quick overview of runtime behavior.

---

### <img src="https://prometheus.io/assets/prometheus_logo_grey.svg" width="24" alt="" /> Prometheus & Alertmanager — alerts

| |
|:--:|
| **[Prometheus alerts](https://i.postimg.cc/7Z5rWFnd/Screenshot-2026-03-14-at-11-06-25-PM.png)** |
| <a href="https://i.postimg.cc/7Z5rWFnd/Screenshot-2026-03-14-at-11-06-25-PM.png"><img src="https://i.postimg.cc/7Z5rWFnd/Screenshot-2026-03-14-at-11-06-25-PM.png" alt="Prometheus Alerts" width="720" /></a> |

Prometheus alerting rules fire when error rates, latency, or resource usage cross defined thresholds. Alertmanager then routes these alerts to Slack and email receivers.

---

### <img src="https://upload.wikimedia.org/wikipedia/commons/d/d5/Slack_icon_2019.svg" width="24" alt="" /> Slack — operational notifications

| |
|:--:|
| **[Slack alert channel](https://i.postimg.cc/MKPvR8Gs/Screenshot-2026-03-14-at-11-07-38-PM.png)** |
| <a href="https://i.postimg.cc/MKPvR8Gs/Screenshot-2026-03-14-at-11-07-38-PM.png"><img src="https://i.postimg.cc/MKPvR8Gs/Screenshot-2026-03-14-at-11-07-38-PM.png" alt="Slack Alerts" width="720" /></a> |

A dedicated Slack channel receives real-time alerts for MI and platform issues so the team can react quickly, with alert details such as name, severity, and affected service.

---

### 📧 Email — alert notifications

| |
|:--:|
| **[Email alert](https://i.postimg.cc/gJD7JsKq/Screenshot-2026-03-15-at-1-34-59-AM.png)** |
| <a href="https://i.postimg.cc/gJD7JsKq/Screenshot-2026-03-15-at-1-34-59-AM.png"><img src="https://i.postimg.cc/gJD7JsKq/Screenshot-2026-03-15-at-1-34-59-AM.png" alt="Email Alerts" width="720" /></a> |

Email is configured as an additional Alertmanager receiver, providing redundancy to Slack and ensuring critical alerts reach on-call engineers even if chat notifications are missed.

---
