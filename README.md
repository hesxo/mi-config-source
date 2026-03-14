# 📦 mi-config-source

Source repository for **WSO2 Micro Integrator (MI)** configurations, Newman integration tests, and the Jenkins CI pipeline. The pipeline builds a custom MI Docker image, runs tests, updates the GitOps manifests repo, and **Argo CD** syncs those manifests to the cluster.

## 🔧 Tech stack

| Logo | Layer | Technology |
|:----:|-------|------------|
| <img src="https://wso2.cachefly.net/wso2/sites/all/2023/images/webp/wso2-logo.webp" width="28" alt="WSO2" /> | **Runtime** | [WSO2 Micro Integrator](https://wso2.com/integration/micro-integrator/) 4.5.0 |
| <img src="https://apache.org/images/feather-small.gif" width="28" alt="Apache" /> | **API config** | Apache Synapse (XML APIs in `src/synapse-config/api/`) |
| <img src="https://upload.wikimedia.org/wikipedia/commons/8/89/Docker_Logo.svg" width="28" alt="Docker" /> | **Container** | [Docker](https://www.docker.com/) (multi-stage build, image `hesxo/mi-config`) |
| <img src="https://upload.wikimedia.org/wikipedia/commons/e/e9/Jenkins_logo.svg" width="28" alt="Jenkins" /> | **CI/CD** | [Jenkins](https://www.jenkins.io/) (declarative pipeline) |
| <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/postman/postman-original.svg" width="28" alt="Postman" /> | **Testing** | [Newman](https://www.npmjs.com/package/newman) (Postman collections), Bash, `curl` |
| <img src="https://raw.githubusercontent.com/argoproj/argo-cd/master/docs/assets/logo.png" width="28" alt="Argo CD" /> | **GitOps CD** | [Argo CD](https://argo-cd.readthedocs.io/) — syncs [mi-manifests](https://github.com/hesxo/mi-manifests) (`overlays/prod`) to Kubernetes |
| <img src="https://upload.wikimedia.org/wikipedia/commons/c/c2/GitHub_Invertocat_Logo.svg" width="28" alt="GitHub" /> | **Source / GitOps** | [GitHub](https://github.com/) — this repo (source); [mi-manifests](https://github.com/hesxo/mi-manifests) (Kustomize base + overlays, Argo CD Application) |

## 📋 Overview

- **Base image:** `wso2/wso2mi:4.5.0`
- **Docker image:** `hesxo/mi-config` (tagged with short Git commit SHA)
- **GitOps repo:** [hesxo/mi-manifests](https://github.com/hesxo/mi-manifests) — deployment image is updated on each successful pipeline run

The included **HelloAPI** exposes `GET /hello/` on port **8290** and returns JSON: `{"message":"hello from WSO2 MI"}`.

## 🔀 Deployment flow

1. **This repo** — You push code (Synapse APIs, Dockerfile, tests).
2. **Jenkins** — Builds the Docker image, pushes to Docker Hub, runs Newman tests, then updates [mi-manifests](https://github.com/hesxo/mi-manifests) `base/deployment.yaml` with the new image tag.
3. **Argo CD** — Watches the mi-manifests repo; when `base/deployment.yaml` (or overlays) change, it syncs `overlays/prod` to the cluster (namespace `mi-prod`).
4. **Kubernetes** — Runs the MI deployment with the new image.

So: **source (here) → Jenkins → Docker Hub + mi-manifests → Argo CD → cluster.**

## 📂 Related repositories

| Repo | Purpose |
|------|---------|
| **mi-manifests** | GitOps repo: Kustomize base (Deployment, Service) + `overlays/prod`, and Argo CD `Application` that points to `overlays/prod`. Jenkins updates the image tag here; Argo CD syncs from here. |

## 📁 Repository structure

```
mi-config-source/
├── .gitignore
├── Dockerfile                    # MI image with synapse configs
├── Jenkinsfile                   # CI: build, test, push image, update GitOps
├── README.md
├── src/
│   └── synapse-config/
│       └── api/                  # Synapse API definitions (e.g. HelloAPI.xml)
├── integration/
│   └── newman/
│       ├── collection.json      # Postman/Newman test collection
│       └── environment.json     # Newman env (baseUrl); overwritten in CI
└── scripts/
    └── run-newman.sh            # Runs Newman against the collection + env
```

## ✅ Prerequisites

- **Docker** — for building and running the MI image
- **Newman** (optional, for local integration tests): `npm install -g newman`
- **Jenkins** (for CI): Docker Hub and GitHub credentials configured
- **Argo CD** (for GitOps): Optional; deploy the [Argo CD Application](https://github.com/hesxo/mi-manifests/blob/main/argocd/mi-application.yaml) from mi-manifests to sync the app to Kubernetes

## 🚀 Build and run locally

```bash
# Build the image
docker build -t hesxo/mi-config:local .

# Run (ports 8290, 8253, 9164)
docker run -p 8290:8290 -p 8253:8253 -p 9164:9164 hesxo/mi-config:local
```

**Test the API:**

```bash
curl http://localhost:8290/hello/
# {"message":"hello from WSO2 MI"}
```

## 📮 Testing in Postman (step-by-step)

Follow these steps to test the MI Hello API from Postman.

### Step 1: Prerequisites

- Install [Docker](https://www.docker.com/get-started) and [Postman](https://www.postman.com/downloads/).
- Open a terminal in the project root: `mi-config-source/`.

### Step 2: Build the MI image

```bash
docker build -t hesxo/mi-config:local .
```

Wait until the build finishes successfully.

### Step 3: Run the MI container

```bash
docker run -p 8290:8290 -p 8253:8253 -p 9164:9164 hesxo/mi-config:local
```

Leave this terminal open. MI is now serving on **port 8290**. Wait a few seconds for startup (you may see “WSO2 Micro Integrator started” in the logs).

### Step 4: Open Postman

Launch the Postman app.

### Step 5: Import the collection

1. Click **Import** (top left).
2. Click **Upload Files** or drag and drop.
3. Select: `mi-config-source/integration/newman/collection.json`.
4. Click **Import**. You should see the collection **“MI Hello API Tests”**.

### Step 6: Import the environment

1. Click **Import** again.
2. Select: `mi-config-source/integration/newman/environment.json`.
3. Click **Import**. You should see the environment **“MI Ephemeral Test”**.

### Step 7: Set the base URL for local MI

1. Click the **Environments** (gear) icon in the left sidebar.
2. Open **MI Ephemeral Test**.
3. Set **CURRENT VALUE** of `baseUrl` to: `http://localhost:8290`  
   (The initial value may be `http://host.docker.internal:18290`; change it for local testing.)
4. Click **Save**.

### Step 8: Select the environment

In the top-right of Postman, open the environment dropdown and select **MI Ephemeral Test**.

### Step 9: Send the request

1. In the left sidebar, expand **MI Hello API Tests**.
2. Click the request **GET /hello/**.
3. The URL should show `{{baseUrl}}/hello/` (resolved to `http://localhost:8290/hello/`).
4. Click **Send**.

### Step 10: Check the response

- **Status:** `200 OK`
- **Body (JSON):**

  ```json
  {
    "message": "hello from WSO2 MI"
  }
  ```

If you see this, the API is working. To test without the collection, use a new request: **GET** `http://localhost:8290/hello/`.

---

## 🧪 Integration tests (Newman)

Tests are defined in `integration/newman/collection.json` and use `integration/newman/environment.json` for the `baseUrl` variable.

**Local (MI on host):**

```bash
# Ensure MI is running on the port set in environment.json (e.g. 8290)
./scripts/run-newman.sh
```

**CI:** The Jenkinsfile prepares `environment.json` with `baseUrl: http://host.docker.internal:8290`, waits for the MI endpoint to be ready, then runs `./scripts/run-newman.sh`.

## 🔄 CI pipeline (Jenkins)

| Stage | Description |
|-------|-------------|
| **Checkout** | Clone this repo |
| **Build Docker Image** | `docker build -t $IMAGE .` (tag = short commit SHA) |
| **Push Docker Image** | Push to Docker Hub using `dockerhub-creds` |
| **Prepare Newman Environment** | Write `integration/newman/environment.json` with MI base URL for tests |
| **Run Integration Tests** | Poll `http://host.docker.internal:8290/hello/` (up to 12×5s), then run Newman |
| **Update GitOps Repo** | Clone `mi-manifests`, update `base/deployment.yaml` image to `$IMAGE`, commit and push using `github-creds` |

After the push, **Argo CD** (if installed and watching mi-manifests) will detect the change and sync the app to the cluster.

**Required Jenkins credentials:**

- `dockerhub-creds` — Username/Password for Docker Hub
- `github-creds` — Username/Password (or token) for GitHub (mi-manifests push)

## ✏️ Adding or changing APIs

1. Add or edit XML files under `src/synapse-config/api/` (e.g. `HelloAPI.xml`).
2. Rebuild the image and run Newman to verify.
3. Commit and push; Jenkins will build, test, and update the GitOps repo.

## 📄 License

See the repository license file if present.
