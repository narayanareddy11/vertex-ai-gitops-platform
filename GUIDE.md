# End-to-End Platform Guide

## Vertex AI GitOps Platform — Complete Reference

> **Who this is for:** Platform engineers, MLOps engineers, and DevOps engineers
> who want to understand every component, why it exists, how it works in real
> financial services environments, and exactly how to install it from scratch.

---

## Table of Contents

1. [What Is This Platform?](#1-what-is-this-platform)
2. [Why Each Tool Exists](#2-why-each-tool-exists)
3. [Real-World Use Cases](#3-real-world-use-cases)
4. [Architecture Explained](#4-architecture-explained)
5. [Prerequisites](#5-prerequisites)
6. [Step-by-Step Installation](#6-step-by-step-installation)
7. [Verify Every Service](#7-verify-every-service)
8. [Deploy the Applications](#8-deploy-the-applications)
9. [Run a Full CI/CD Pipeline](#9-run-a-full-cicd-pipeline)
10. [Troubleshooting](#10-troubleshooting)
11. [Reset Everything](#11-reset-everything)

---

## 1. What Is This Platform?

This platform answers one question:

> **"How do you deploy an AI/ML model into production in a bank — safely,
> with full audit trail, zero static credentials, and automatic rollback
> if something goes wrong?"**

In a normal company you might `docker run` your model and hope for the best.
In a regulated institution (Lloyds, Barclays, Goldman Sachs) you cannot do that.
Every deployment must be:

| Requirement | Why It Exists |
|-------------|---------------|
| Approved by a risk committee | FCA Model Risk rules (SR 11-7, SS1/23) |
| Recorded in an immutable audit log | PRA Change Management requirements |
| Encrypted in transit between services | PRA/FCA zero-trust mandate |
| Free of hard-coded credentials | NCSC Cyber Essentials / ISO 27001 |
| Rolled out gradually with automatic rollback | Operational resilience requirements |
| Monitored for data drift | SR 11-7 ongoing model monitoring |

This platform implements all six requirements using open-source tools that run
on a single Mac laptop — so you can demonstrate it in an interview or POC without
needing a cloud account.

---

## 2. Why Each Tool Exists

### Kubernetes — The Foundation
**What it is:** Container orchestration — runs and manages your applications as pods.

**Why you need it:**
Banks run hundreds of microservices. Kubernetes ensures each service has the right
amount of CPU/memory, restarts if it crashes, and scales under load. Every other
tool in this stack runs inside Kubernetes.

**Real-world use:** Lloyds runs all their cloud-native workloads on AKS (Azure
Kubernetes Service). Barclays uses EKS. Goldman Sachs uses their own internal
Kubernetes platform called "Marquee Infrastructure".

**Without it:** You'd be running `docker run` on a VM with no self-healing, no
scaling, and no service discovery.

---

### Istio — Service Mesh (mTLS)
**What it is:** A network layer that sits between every service and encrypts +
authenticates all traffic automatically.

**Why you need it:**
Banks must encrypt all internal traffic, not just external. Without Istio,
traffic between your model service and your API service is plain HTTP inside
the cluster — readable by anyone who compromises a node.

Istio injects a sidecar proxy (Envoy) into every pod. The sidecars negotiate
TLS certificates automatically using SPIFFE/SPIRE identity — no certificate
management needed.

**Real-world use:** "Strict mTLS" mode means if any pod tries to talk to another
pod without a valid certificate, the connection is rejected. This is the zero-trust
network model mandated by FCA Operational Resilience rules.

**Without it:** Internal service traffic is unencrypted. A compromised pod can
sniff passwords, tokens, and model inputs from other services.

```
Pod A  ──plaintext──►  Pod B        ← WITHOUT Istio (insecure)
Pod A  ──mTLS──────►  Pod B        ← WITH Istio (zero-trust)
       (Envoy)        (Envoy)
```

---

### HashiCorp Vault — Secrets Management
**What it is:** A secrets store that issues dynamic credentials to applications
based on their Kubernetes identity.

**Why you need it:**
Hard-coded passwords in environment variables or config files are the #1 cause
of data breaches. Vault eliminates them entirely.

When a pod starts, its Vault Agent sidecar:
1. Reads the pod's Kubernetes ServiceAccount JWT token
2. Sends it to Vault: "I am pod X in namespace apps"
3. Vault verifies it with the Kubernetes API
4. Returns a short-lived secret (expires in 1 hour)
5. Agent writes it to `/vault/secrets/` as a file

**Real-world use:** Goldman Sachs uses Vault for all internal service credentials.
Lloyds uses it to manage database passwords for their core banking systems.
No engineer ever sees the actual password — only the application does, and only
for one hour.

**Without it:** Passwords live in Git (a disaster), or in Kubernetes Secrets
(base64 encoded, not encrypted at rest by default — also a disaster).

```
❌ BAD:  DB_PASSWORD=mypassword123  (in .env file, committed to Git)
✅ GOOD: vault kv get secret/myapp  (issued dynamically, expires in 1h)
```

---

### Jenkins — Continuous Integration (CI)
**What it is:** An automation server that runs your pipeline every time you push code.

**Why you need it:**
Before any code reaches production it must be checked for:
- Security vulnerabilities in your Python packages (Snyk)
- CVEs in your Docker image (Trivy)
- Code security issues (Bandit SAST)
- Model governance — does this deployment have an approved model card?

Jenkins runs all these checks automatically. If any check fails, the deployment
is blocked. This is called a "quality gate."

**Real-world use:** Lloyds Banking Group runs a Jenkins estate of 2,000+ jobs.
Barclays uses Jenkins for their entire trading platform CI. The Kubernetes agent
plugin (used here) means each build runs in a fresh pod — no shared state between
builds.

**Pipeline stages in this platform:**
```
git push
  └─► Jenkins detects change
        ├─ Stage 1: SAST    — Bandit scans Python source code
        ├─ Stage 2: Snyk    — checks requirements.txt for CVEs
        ├─ Stage 3: Trivy   — scans Docker image for CVEs
        ├─ Stage 4: ModelCard — validates model-card.yaml exists
        ├─ Stage 5: Build   — docker buildx (multi-arch arm64/amd64)
        ├─ Stage 6: Push    — pushes image to registry
        └─ Stage 7: Notify  — triggers Harness CD pipeline
```

---

### ArgoCD — GitOps (Continuous Delivery)
**What it is:** A Kubernetes controller that continuously watches a Git repository
and ensures the cluster matches what's in Git.

**Why you need it:**
Traditional CD (`kubectl apply` from a pipeline) is push-based — the pipeline
pushes changes to the cluster. This means:
- The cluster can drift from Git without anyone noticing
- There's no automatic rollback if someone runs `kubectl edit` manually
- It's hard to see "what is actually running" vs "what should be running"

ArgoCD flips this. It pulls changes from Git every 3 minutes. If the cluster
drifts, it auto-heals back to the Git state. Every running workload is tied to
a specific Git commit SHA.

**Real-world use:** "App-of-Apps" pattern (used here) is how Barclays manages
50+ microservices — one root ArgoCD application points to a folder of application
definitions, which each deploy their own Helm chart.

**Audit trail:** Regulators can ask "what was running in production on March 15th?"
and you answer with a Git commit hash.

```
Git repo (source of truth)
    │
    ▼  (ArgoCD polls every 3 min)
Kubernetes cluster (auto-healed to match Git)
    │
    ▼
If someone does `kubectl edit` manually...
    │
    ▼  (ArgoCD detects drift)
Auto-revert back to Git state  ← audit trail preserved
```

---

### Harness CD — Progressive Delivery
**What it is:** A SaaS deployment platform that orchestrates canary releases with
automated verification and human approval gates.

**Why you need it:**
ArgoCD deploys what's in Git, but it doesn't control *how* you roll it out.
Harness adds:
- **Canary deployment** — send 10% of traffic to the new version first
- **Automated verification** — check Prometheus: if error rate > 1%, auto-rollback
- **Approval gate** — require a human to sign off before 100% rollout

**Real-world use:** At Goldman Sachs, every production deployment to their trading
platform requires a canary verification and a sign-off from a senior engineer.
If the canary fails metrics checks, it rolls back within 2 minutes — before most
users even see it.

```
New version deployed
    │
    ▼
10% traffic → new version  │  90% → old version
    │
    ▼ (5 min verification)
Prometheus check: error_rate < 1%? p99 < 500ms?
    ├─ YES → human approval gate → promote to 100%
    └─ NO  → automatic rollback  → alert on-call engineer
```

---

### OPA Gatekeeper — Policy as Code
**What it is:** A Kubernetes admission controller that enforces policies on every
resource before it's allowed into the cluster.

**Why you need it:**
In a bank, you cannot allow any developer to deploy any model they like. Every
ML model must have:
- An approved model card (who trained it, what data, what risk level)
- Resource limits (to prevent one model starving others of CPU/memory)
- No privileged containers (security requirement)

OPA Gatekeeper enforces these as Kubernetes admission webhooks — the pod is
rejected before it ever runs if it violates policy.

**Real-world use:** FCA's SS1/23 guidance requires banks to maintain a "model
inventory" and document the purpose, risk, and approval status of every model.
The `RequireModelCard` constraint implements this — no model deploys without an
approved card.

```
kubectl apply -f my-model-pod.yaml
    │
    ▼
OPA Gatekeeper webhook intercepts
    │
    ├─ Has ai.platform/model-card annotation? → NO → REJECTED ❌
    ├─ Has CPU/memory limits?                 → NO → REJECTED ❌
    ├─ Is it privileged?                      → YES → REJECTED ❌
    │
    └─ All checks pass                             → ALLOWED  ✅
```

---

### Prometheus + Grafana — Metrics & Dashboards
**What it is:** Prometheus collects time-series metrics. Grafana visualises them.

**Why you need it:**
You need to know in real time:
- How many predictions per second is your model serving?
- What is the p99 latency? (How slow is the 1% slowest request?)
- Is the error rate increasing?
- Is there a memory leak?

**Real-world use:** Barclays has SLOs (Service Level Objectives) on all ML models:
"prediction latency p99 < 200ms, availability > 99.9%." Prometheus alerts when
SLOs are breached. Grafana dashboards are on screens in the ops room.

**Metrics this platform tracks:**
```
ml_model_predictions_total          — total predictions served
ml_model_prediction_seconds         — latency histogram (p50, p95, p99)
ml_model_accuracy                   — training accuracy (0.8925)
ml_model_drift_score                — Evidently drift detection score
sample_app_requests_total           — HTTP request count by status code
sample_app_request_duration_seconds — HTTP request latency
```

---

### Jaeger — Distributed Tracing
**What it is:** Captures the full journey of a request across multiple services.

**Why you need it:**
When a prediction request fails, which service caused it? The request might go:
`API Gateway → sample-app → ml-model → feature store → database`

Without tracing, you look at 4 separate log files and try to correlate timestamps.
With Jaeger, you see the full trace as a waterfall — exactly which span was slow
and why.

**Real-world use:** When Goldman's trading platform had a latency spike, the Jaeger
trace showed the bottleneck was in the feature normalisation step, not the model
inference — saving hours of investigation.

---

### Kiali — Service Mesh Topology
**What it is:** A visual dashboard showing real-time traffic flow between all
services in the Istio mesh.

**Why you need it:**
As your platform grows to 50 services, you need to see:
- Which services are talking to which?
- What is the error rate on each connection?
- Is mTLS actually active on all links?

**Real-world use:** Lloyds uses Kiali to show compliance auditors that all
internal traffic is mTLS-encrypted — one screenshot showing all green locks
is worth more than 100 pages of documentation.

---

### Evidently AI — Model Drift Detection
**What it is:** Compares live production data distributions against training data
to detect when a model's inputs have changed enough to affect its accuracy.

**Why you need it:**
A model trained on 2024 customer data might perform poorly on 2026 data because
customer behaviour changed. Without drift detection, you don't know — the model
silently gives bad predictions.

**Real-world use:** SS1/23 (FCA model risk supervision) requires banks to monitor
model performance in production. Evidently runs as a Kubernetes CronJob every
15 minutes, pushes a drift score to Prometheus, and Grafana alerts if drift > 0.25.

---

### MCP AI Agent — Autonomous Incident Response
**What it is:** An AI agent (powered by Claude API) with tools to query Prometheus,
read Jaeger traces, roll back deployments, and create incident tickets.

**Why you need it:**
At 3 AM, a model starts returning errors. The on-call engineer is asleep.
The MCP agent:
1. Detects the alert from Prometheus
2. Queries Jaeger traces to find the root cause span
3. Decides: "the new model version caused this"
4. Rolls back the deployment to the previous version
5. Creates a PagerDuty incident
6. Posts an RCA summary to Slack — before anyone wakes up

**Real-world use:** NVIDIA's AI infrastructure team uses MCP-based agents for
auto-remediation of GPU cluster issues. This is the direction all major platform
teams are moving.

---

### Terraform — Infrastructure as Code
**What it is:** Declarative configuration language for cloud infrastructure.

**Why you need it:**
When you move from local Kubernetes to AWS EKS or GCP GKE, every resource
(cluster, VPC, IAM roles, managed databases) must be reproducible and version-
controlled. Terraform modules in this repo are ready to apply to AWS or GCP.

**Real-world use:** Goldman Sachs requires all infrastructure to be created via
Terraform — no manual console clicks. Every change goes through code review and
leaves an audit trail in Git.

---

## 3. Real-World Use Cases

### Use Case 1 — New Model Deployment at Lloyds

```
Data scientist trains fraud detection model
    │
    ▼
Opens PR → Jenkins runs: SAST + Snyk + Trivy + model-card check
    │                    (blocks if model-card.yaml missing)
    ▼
PR approved → ArgoCD detects change in helm/ml-model/values.yaml
    │
    ▼
Harness CD: deploy 10% canary
    ├─ Prometheus: fraud_model_error_rate = 0.002  ← below 1% threshold ✅
    ├─ Prometheus: p99_latency = 180ms             ← below 200ms SLO ✅
    └─ Manual approval gate: Risk Committee signs off
    │
    ▼
Promote to 100%  →  model live  →  Evidently monitors drift every 15 min
```

**Time from PR merge to production: ~15 minutes**
**Manual steps: 1 (approval gate)**
**Audit trail: full Git history + ArgoCD sync log + Harness deployment record**

---

### Use Case 2 — Automatic Rollback at Barclays

```
3:47 AM — New model version deployed
3:52 AM — Prometheus alert: prediction_latency p99 > 500ms
3:52 AM — MCP AI agent wakes up
3:53 AM — Agent queries Jaeger: finds slow span in feature normalisation
3:53 AM — Agent calls rollback_deployment("ml-model", "previous")
3:54 AM — Old version restored, latency returns to normal
3:54 AM — PagerDuty incident created (severity: P2)
3:54 AM — Slack: "Auto-rollback completed. Root cause: feature normaliser
           timeout in new model version. Incident #4521 created."
4:00 AM — On-call engineer reads Slack summary with morning coffee ☕
```

**Time to resolution: 7 minutes**
**Engineers woken up: 0**

---

### Use Case 3 — Compliance Audit at Goldman Sachs

```
Regulator asks: "Show me all ML models in production and their approval status"
    │
    ▼
OPA Gatekeeper: lists all pods with ai.platform/model-card annotation
    │
    ▼
model-card.yaml for each model shows:
  - approved-by: model-risk-committee
  - approval-date: 2026-04-19
  - regulatory: {fca-sr11-7: compliant, ss1-23: compliant}
    │
    ▼
ArgoCD history shows every deployment with Git commit SHA and timestamp
    │
    ▼
Vault audit log shows every time a secret was accessed and by which pod
    │
    ▼
Full audit package assembled in < 1 hour  ✅
```

---

## 4. Architecture Explained

### Data Flow — A Prediction Request

```
User/Client
    │
    │  POST /predict {"features": [1.2, -0.5, ...]}
    ▼
Istio Ingress Gateway  (NodePort 30080)
    │
    │  mTLS (certificate verified by SPIFFE)
    ▼
sample-app pod  (namespace: apps)
    │  Envoy sidecar intercepts, verifies client cert
    │
    ├─► Prometheus: increments sample_app_requests_total
    ├─► Jaeger: starts trace span "handle-predict"
    │
    │  POST /predict  (internal call to ml-model)
    ▼
ml-model pod  (namespace: ml-platform)
    │  Envoy sidecar verifies mTLS from sample-app
    │
    ├─► joblib.load("model.joblib") → RandomForest.predict()
    ├─► Prometheus: increments ml_model_predictions_total
    ├─► Jaeger: child span "rf-inference" (latency: 6.81ms)
    │
    ▼
Response: {"prediction": 1, "probability": [0.38, 0.62], "latency_ms": 6.81}
    │
    ▼
sample-app returns to client
    │
    ▼  (every 15 minutes)
Evidently drift job compares request features to training distribution
    └─► pushes drift_score to Prometheus
        └─► Grafana alert if drift_score > 0.25
```

---

### Secret Flow — How Apps Get Credentials

```
ml-model pod starts
    │
    ├─ Vault Agent sidecar reads ServiceAccount JWT
    ├─ POST vault/v1/auth/kubernetes/login  {"jwt": "...", "role": "ml-platform-role"}
    ├─ Vault verifies JWT with Kubernetes API ← pod identity, not password
    ├─ Returns: {"token": "s.abc123", "ttl": "3600s"}
    ├─ GET vault/v1/secret/data/ml-model
    └─ Writes to /vault/secrets/config:
         model_version=1.0.0
         registry=docker.io/yourorg
    │
    ▼
Application reads /vault/secrets/config  ← no env vars, no hardcoded secrets
Token expires in 1 hour → Vault Agent auto-renews
```

---

## 5. Prerequisites

### Hardware

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| Mac chip | Apple M1 | M2 / M3 |
| RAM | 16 GB | 16 GB |
| Docker Desktop RAM | 8 GB | 10 GB |
| Free disk | 20 GB | 40 GB |

### Software

| Tool | Version | Check |
|------|---------|-------|
| macOS | Sonoma 14+ | `sw_vers` |
| Docker Desktop | 4.28+ | `docker --version` |
| Kubernetes (Docker Desktop) | Enabled | Settings → Kubernetes |
| Homebrew | Any | `brew --version` |
| Git | Any | `git --version` |

### Docker Desktop Kubernetes Setup

1. Open **Docker Desktop**
2. Click **Settings** (gear icon)
3. Click **Kubernetes** in left panel
4. Tick **Enable Kubernetes**
5. Click **Apply & Restart**
6. Wait ~2 minutes for green Kubernetes badge (bottom left)
7. Set Docker Desktop resources:
   - **CPUs**: 6
   - **Memory**: 10 GB
   - **Swap**: 2 GB

---

## 6. Step-by-Step Installation

### Clone the Repository

```bash
git clone https://github.com/narayanareddy11/vertex-ai-gitops-platform.git
cd vertex-ai-gitops-platform
```

### Script 00 — Preflight Check

**What it does:** Validates Kubernetes is reachable, RAM is sufficient, required
CLIs are installed, and disk space is available.

```bash
./scripts/00-preflight-check.sh
```

**Expected output:**
```
[OK]  Kubernetes reachable: docker-desktop
[OK]  Nodes ready: 1
[OK]  helm found
[OK]  kubectl found
[OK]  Free disk: 427GB
Preflight PASSED — ready to install.
```

**If it fails:** Address each `[FAIL]` item before continuing.

---

### Script 01 — Install CLI Tools

**What it does:** Installs all required command-line tools via Homebrew and direct
binary downloads. Adds all Helm repositories. Safe to re-run — skips already
installed tools.

```bash
./scripts/01-install-tools.sh
```

**Tools installed:**
| Tool | Purpose |
|------|---------|
| `helm` | Kubernetes package manager |
| `argocd` | ArgoCD CLI for GitOps management |
| `istioctl` | Istio service mesh CLI |
| `vault` | HashiCorp Vault CLI (binary download, no Xcode needed) |
| `opa` | Open Policy Agent CLI for policy testing |
| `terraform` | Infrastructure as Code CLI |
| `snyk` | Software composition analysis (SCA) |
| `trivy` | Container image CVE scanner |

**Helm repos added:**
`jenkins` · `argo` · `hashicorp` · `istio` · `open-policy-agent`
`prometheus` · `grafana` · `jaeger` · `kiali`

**Time:** ~3 minutes (first run), ~10 seconds (re-run)

---

### Script 02 — Kubernetes Namespaces & Network Policies

**What it does:** Creates all namespaces, enables Istio sidecar injection on
application namespaces, and applies default-deny NetworkPolicies.

```bash
./scripts/02-setup-kubernetes.sh
```

**Namespaces created:**

| Namespace | Used For |
|-----------|---------|
| `apps` | sample-app FastAPI service |
| `ml-platform` | ml-model inference service |
| `vault` | HashiCorp Vault |
| `jenkins` | Jenkins CI server |
| `argocd` | ArgoCD GitOps engine |
| `monitoring` | Prometheus, Grafana, Jaeger |
| `istio-system` | Istio control plane + Kiali |
| `gatekeeper-system` | OPA Gatekeeper |

**NetworkPolicies applied:**
- `default-deny` on `apps` and `ml-platform` — blocks all traffic by default
- `allow-intra-namespace` — allows traffic within same namespace + from monitoring

**Time:** ~15 seconds

---

### Script 03 — Install Istio

**What it does:** Installs Istio service mesh (base + control plane + ingress
gateway) and enforces strict mTLS cluster-wide.

```bash
./scripts/03-install-istio.sh
```

**Components installed:**
- `istio-base` — CRDs and cluster roles
- `istiod` — Istio control plane (Pilot, Citadel, Galley)
- `istio-ingress` — Ingress gateway (NodePort for local access)
- `PeerAuthentication` — cluster-wide STRICT mTLS policy

**Why STRICT mode matters:** Any pod that tries to connect to another pod without
a valid mTLS certificate gets an immediate TCP RST. No exceptions.

**Verify after install:**
```bash
kubectl get peerauthentication -n istio-system
# NAME      MODE     AGE
# default   STRICT   2m
```

**Time:** ~3 minutes

---

### Script 04 — Install HashiCorp Vault

**What it does:** Deploys Vault in dev mode, configures Kubernetes auth backend,
creates policies, and seeds demo secrets.

```bash
./scripts/04-install-vault.sh
```

**What gets configured:**
```
Vault dev mode (root token = "root")
├── auth/kubernetes enabled
│   ├── role: apps-role      → namespace: apps
│   ├── role: ml-platform-role → namespace: ml-platform
│   └── role: jenkins-role   → namespace: jenkins
├── policy: app-policy       → read secret/data/*
└── secrets seeded:
    ├── secret/sample-app    → db_password, api_key
    └── secret/ml-model      → model_version, registry
```

**Access Vault UI:**
```bash
kubectl port-forward -n vault svc/vault 8200:8200 &
# Open http://localhost:8200
# Token: root
```

**⚠ Dev mode warning:** Secrets are lost when the Vault pod restarts.
For production, use `terraform/modules/vault` with Raft storage.

**Time:** ~2 minutes

---

### Script 05 — Install Jenkins

**What it does:** Deploys Jenkins via Helm with the Kubernetes agent plugin
pre-installed. Each build runs in a fresh ephemeral pod.

```bash
./scripts/05-install-jenkins.sh
```

**Plugins pre-installed:**
- `kubernetes` — ephemeral build agents in pods
- `workflow-aggregator` — pipeline as code
- `git` — source control integration
- `blueocean` — modern pipeline UI
- `docker-workflow` — Docker build/push in pipelines
- `snyk-security-scanner` — Snyk SCA integration

**Access Jenkins:**
```bash
kubectl port-forward -n jenkins svc/jenkins 8888:8080 &
# Open http://localhost:8888
# Username: admin  Password: admin123
```

**Time:** ~5 minutes (JVM startup is slow)

---

### Script 06 — Install ArgoCD

**What it does:** Deploys ArgoCD, logs in via CLI, and registers the
docker-desktop cluster.

```bash
./scripts/06-install-argocd.sh
```

**After install:**
```bash
# Get auto-generated admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Access UI
kubectl port-forward -n argocd svc/argocd-server 8080:80 &
# Open http://localhost:8080
# Username: admin  Password: (from above)
```

**Deploy all apps via GitOps:**
```bash
kubectl apply -f argocd/app-of-apps.yaml
```

**Time:** ~3 minutes

---

### Script 07 — Install OPA Gatekeeper

**What it does:** Deploys OPA Gatekeeper and applies three ConstraintTemplates
and two Constraints.

```bash
./scripts/07-install-opa-gatekeeper.sh
```

**Policies enforced:**

| Policy | Scope | Action |
|--------|-------|--------|
| `RequireModelCard` | `ml-platform` namespace | Deny pod if no `ai.platform/model-card` annotation |
| `RequireResourceLimits` | `apps`, `ml-platform` | Deny pod if no CPU/memory limits |
| `DenyPrivilegedContainers` | `apps`, `ml-platform` | Deny pod if `securityContext.privileged=true` |

**Test the policy:**
```bash
# This should be DENIED (no model-card annotation)
kubectl apply -n ml-platform -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: test-no-card
spec:
  containers:
  - name: test
    image: nginx
EOF
# Error: admission webhook denied: Pod must have ai.platform/model-card annotation
```

**Time:** ~2 minutes

---

### Script 08 — Install Observability Stack

**What it does:** Deploys Prometheus + Grafana (kube-prometheus-stack), Jaeger
all-in-one, and Kiali. Configures Istio telemetry integration.

```bash
./scripts/08-install-observability.sh
```

**Services installed:**

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://localhost:3000 | admin / admin |
| Prometheus | http://localhost:9090 | — |
| Jaeger | http://localhost:16686 | — |
| Kiali | http://localhost:20001 | — |

**Start all observability port-forwards:**
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
kubectl port-forward -n monitoring svc/jaeger 16686:16686 &
kubectl port-forward -n istio-system svc/kiali 20001:20001 &
```

**Time:** ~5 minutes

---

### Script 09 — Install Harness Delegate (Optional)

**What it does:** Deploys the Harness CD Delegate inside the cluster.
Requires a free account at app.harness.io.

```bash
# Only if you have a Harness account:
HARNESS_DELEGATE_TOKEN=<your-token> \
HARNESS_ACCOUNT_ID=<your-account-id> \
./scripts/09-install-harness-delegate.sh

# Otherwise, skip — all other services work without it
./scripts/09-install-harness-delegate.sh  # exits gracefully with instructions
```

---

## 7. Verify Every Service

Run this block to check every service at once:

```bash
echo "=== Kubernetes Nodes ==="
kubectl get nodes

echo "=== All Pods (non-system) ==="
kubectl get pods -A | grep -v kube-system

echo "=== Port Checks ==="
for port in 8080 8888 8200 3000 9090 16686 20001 8000 8001; do
  nc -z localhost $port 2>/dev/null \
    && echo "✅  localhost:$port  OPEN" \
    || echo "❌  localhost:$port  CLOSED"
done
```

**Expected output:**
```
✅  localhost:8080   OPEN  — ArgoCD
✅  localhost:8888   OPEN  — Jenkins
✅  localhost:8200   OPEN  — Vault
✅  localhost:3000   OPEN  — Grafana
✅  localhost:9090   OPEN  — Prometheus
✅  localhost:16686  OPEN  — Jaeger
✅  localhost:20001  OPEN  — Kiali
✅  localhost:8000   OPEN  — sample-app
✅  localhost:8001   OPEN  — ml-model
```

---

## 8. Deploy the Applications

### Start Apps Locally (Python — fastest)

```bash
# Create Python 3.11 environment
/opt/homebrew/bin/python3.11 -m venv .venv
source .venv/bin/activate
pip install fastapi uvicorn pydantic prometheus-client scikit-learn joblib numpy pandas httpx

# Train the ML model
python3 -c "
import joblib, numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.datasets import make_classification
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score
import json, os
os.makedirs('apps/ml-model/models', exist_ok=True)
X, y = make_classification(n_samples=2000, n_features=10, random_state=42)
X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.2, random_state=42)
m = RandomForestClassifier(n_estimators=100, random_state=42)
m.fit(X_tr, y_tr)
acc = accuracy_score(y_te, m.predict(X_te))
joblib.dump(m, 'apps/ml-model/models/model.joblib')
json.dump({'model_version':'1.0.0','n_features':10,'accuracy':round(float(acc),4),'trained_at':__import__(\"datetime\").datetime.utcnow().isoformat()}, open('apps/ml-model/models/metadata.json','w'))
print(f'Model trained. Accuracy: {acc:.4f}')
"

# Start sample-app on port 8000
APP_VERSION=1.0.0 uvicorn apps.sample-app.src.main:app \
  --host 0.0.0.0 --port 8000 --log-level warning &

# Start ml-model on port 8001
APP_VERSION=1.0.0 uvicorn apps.ml-model.src.serve:app \
  --host 0.0.0.0 --port 8001 --log-level warning &

echo "Apps started. Test with:"
echo "  curl http://localhost:8000/health"
echo "  curl http://localhost:8001/health"
```

### Test the APIs

```bash
# sample-app health
curl http://localhost:8000/health
# {"status":"ok","version":"1.0.0","uptime_seconds":3.2}

# sample-app prediction
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"features":[2.5,3.1,1.8,4.2,0.9]}'
# {"prediction":2.5,"confidence":0.25,"model_version":"v1.0.0","request_id":"..."}

# ml-model health
curl http://localhost:8001/health
# {"status":"ok","model_loaded":true,"model_version":"1.0.0","accuracy":0.8925}

# ml-model prediction (10 features required)
curl -X POST http://localhost:8001/predict \
  -H "Content-Type: application/json" \
  -d '{"features":[1.2,-0.5,2.3,0.8,-1.1,0.4,1.7,-0.9,0.3,1.5]}'
# {"prediction":1,"probability":[0.3771,0.6229],"latency_ms":6.81,...}

# drift status
curl http://localhost:8001/drift
# {"drift_score":0.0,"threshold":0.25,"drifted":false,"status":"healthy"}

# Prometheus metrics
curl http://localhost:8001/metrics | grep ml_model
```

### Interactive API Docs (Swagger UI)

```
http://localhost:8000/docs  — sample-app Swagger UI
http://localhost:8001/docs  — ml-model Swagger UI
```

---

## 9. Run a Full CI/CD Pipeline

### Trigger GitHub Actions (automatic)

```bash
# Any push to apps/ triggers the workflows automatically
git add apps/sample-app/src/main.py
git commit -m "test: trigger CI"
git push origin main
# → Go to https://github.com/narayanareddy11/vertex-ai-gitops-platform/actions
```

### GitHub Actions Test Cases

**Workflow 1: test-sample-app.yml**
```
Test Case 1: Health & Root endpoints
  - GET /health → status=ok, version present
  - GET /      → service=sample-app

Test Case 2: Predict & Metrics endpoints
  - POST /predict [1,2,3] → prediction=2.0, confidence present
  - POST /predict [5.0]   → prediction=5.0 (single feature)
  - GET /metrics          → contains "sample_app_requests_total"
```

**Workflow 2: test-ml-model.yml**
```
Test Case 1: Model training artefact validation
  - model.joblib exists and loads correctly
  - accuracy > 0.80 (actual: 0.8925)
  - predict() returns array of 0s and 1s
  - predict_proba() returns valid probabilities (sum to 1.0)

Test Case 2: Inference API schema validation
  - GET  /health  → status=ok, model_loaded=true
  - POST /predict → prediction int, probability list, latency_ms float
  - GET  /drift   → drift_score float, drifted bool
  - GET  /metrics → contains "ml_model" metrics
```

---

## 10. Troubleshooting

### Kubernetes Won't Start

```bash
# Check Docker Desktop has Kubernetes enabled
# Settings → Kubernetes → Enable Kubernetes → Apply & Restart

# Check context exists
kubectl config get-contexts
# Should show: docker-desktop

# If context is missing, reset:
# Docker Desktop → Troubleshoot → Reset Kubernetes cluster
```

### Pod Stuck in Pending

```bash
kubectl describe pod <pod-name> -n <namespace>
# Look for "Events:" at bottom
# Common causes:
#   Insufficient memory → increase Docker Desktop RAM to 10GB
#   PVC pending        → storage class issue (check local-path-storage pod)
```

### Port Already in Use

```bash
# Kill all port-forwards
pkill -f "kubectl port-forward"

# Find what's using a port
lsof -i TCP:8080

# Restart specific port-forward
kubectl port-forward -n argocd svc/argocd-server 8080:80 &
```

### Vault Secrets Lost After Restart

```bash
# Vault dev mode loses data on restart — re-seed:
kubectl exec -n vault vault-0 -- sh -c '
  export VAULT_TOKEN=root VAULT_ADDR=http://127.0.0.1:8200
  vault kv put secret/sample-app db_password=demo_pass api_key=demo_key
  vault kv put secret/ml-model   model_version=1.0.0 registry=docker.io
'
```

### OPA Blocks Your Pod

```bash
# Check what constraint is blocking
kubectl get events -n ml-platform | grep "denied"

# Temporarily audit instead of deny (for debugging)
kubectl patch constraint require-model-card-ml-platform \
  --type='json' -p='[{"op":"replace","path":"/spec/enforcementAction","value":"warn"}]'
```

### Jenkins Won't Load

```bash
# JVM takes 3-5 minutes to start — check logs
kubectl logs -n jenkins jenkins-0 -f

# If plugins fail to download (no internet):
# Restart pod — plugins are cached after first successful start
kubectl delete pod -n jenkins jenkins-0
```

### Python App Won't Start (module not found)

```bash
# Ensure you're using Python 3.11 venv
source .venv/bin/activate
python --version  # Must be 3.11.x

# If venv is missing:
/opt/homebrew/bin/python3.11 -m venv .venv
source .venv/bin/activate
pip install fastapi uvicorn pydantic prometheus-client scikit-learn joblib numpy
```

---

## 11. Reset Everything

### Soft Reset — Restart Services Only

```bash
# Kill port-forwards
pkill -f "kubectl port-forward"

# Kill Python apps
pkill -f "uvicorn"

# Restart port-forwards
kubectl port-forward -n argocd       svc/argocd-server                         8080:80    &
kubectl port-forward -n jenkins      svc/jenkins                               8888:8080  &
kubectl port-forward -n vault        svc/vault                                 8200:8200  &
kubectl port-forward -n monitoring   svc/prometheus-grafana                    3000:80    &
kubectl port-forward -n monitoring   svc/prometheus-kube-prometheus-prometheus 9090:9090  &
kubectl port-forward -n monitoring   svc/jaeger                                16686:16686 &
kubectl port-forward -n istio-system svc/kiali                                 20001:20001 &
```

### Hard Reset — Reinstall Everything

```bash
# Delete all non-system namespaces
for ns in apps ml-platform vault jenkins argocd monitoring istio-system gatekeeper-system; do
  kubectl delete namespace $ns --ignore-not-found
done

# Reinstall from scratch (takes ~15 minutes)
for i in 02 03 04 05 06 07 08; do
  bash scripts/0${i}-*.sh
done
```

### Full Reset — Reset Kubernetes Cluster

```
Docker Desktop → Troubleshoot → Reset Kubernetes cluster
```
This deletes all pods, namespaces, and Helm releases. Re-run all scripts after.

---

## Summary — Component Map

```
┌─────────────────────────────────────────────────────────────────────┐
│  WHAT YOU BUILD           WHY IT EXISTS          WHERE IT RUNS      │
├─────────────────────────────────────────────────────────────────────┤
│  Kubernetes               Orchestration          docker-desktop     │
│  Istio (mTLS)             Zero-trust network     istio-system ns    │
│  HashiCorp Vault          Dynamic secrets        vault ns           │
│  Jenkins CI               Build + security scan  jenkins ns         │
│  ArgoCD                   GitOps audit trail     argocd ns          │
│  Harness CD               Canary + approval gate SaaS + delegate    │
│  OPA Gatekeeper           Model governance       gatekeeper-system  │
│  Prometheus + Grafana     SLO monitoring         monitoring ns      │
│  Jaeger                   Distributed tracing    monitoring ns      │
│  Kiali                    Mesh topology          istio-system ns    │
│  Evidently AI             Drift detection        CronJob (local)    │
│  MCP AI Agent             Auto incident response local Python       │
│  sample-app (FastAPI)     Demo REST service      apps ns            │
│  ml-model (sklearn)       ML inference service   ml-platform ns     │
│  Terraform                Cloud IaC              local / AWS / GCP  │
└─────────────────────────────────────────────────────────────────────┘
```

---

*Built by Venkata Narayana Reddy Mandhati — Platform / MLOps Engineer*
*GitHub: https://github.com/narayanareddy11/vertex-ai-gitops-platform*
