# Vertex AI GitOps Platform

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Kubernetes](https://img.shields.io/badge/kubernetes-1.35-326CE5?logo=kubernetes)
![Istio](https://img.shields.io/badge/istio-1.29-466BB0?logo=istio)
![ArgoCD](https://img.shields.io/badge/argocd-3.3-EF7B4D?logo=argo)
![Jenkins](https://img.shields.io/badge/jenkins-2.x-D24939?logo=jenkins)
![Vault](https://img.shields.io/badge/vault-1.17-FFEC6E?logo=vault)
![License](https://img.shields.io/badge/license-MIT-green)
![Sample App Tests](https://github.com/narayanareddy11/vertex-ai-gitops-platform/actions/workflows/test-sample-app.yml/badge.svg)
![ML Model Tests](https://github.com/narayanareddy11/vertex-ai-gitops-platform/actions/workflows/test-ml-model.yml/badge.svg)

> **Enterprise AI-safe GitOps platform** — end-to-end ML model lifecycle management
> with policy enforcement, full observability, and autonomous AI incident response.
> Targets senior roles at **Lloyds Banking Group · Barclays · Goldman Sachs · NVIDIA**.

---

## What Is This?

This platform demonstrates how to run AI/ML workloads in production with the same
rigour applied to financial transactions — every model has a governance card, every
deployment is gated, every secret is dynamic, and every anomaly triggers an autonomous
response agent.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│          Mac M1 · Docker Desktop Kubernetes             │
│                                                         │
│  ┌──────────┐   ┌──────────┐   ┌──────────────────┐    │
│  │ Jenkins  │   │ ArgoCD   │   │  Harness CD SaaS │    │
│  │  CI/CD   │──►│  GitOps  │──►│  Canary + Gate   │    │
│  └──────────┘   └──────────┘   └──────────────────┘    │
│                                                         │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐            │
│  │ FastAPI  │   │ sklearn  │   │  Vault   │            │
│  │ sample   │   │ ml-model │   │ Secrets  │            │
│  │   app    │   │  serve   │   │ K8s auth │            │
│  └──────────┘   └──────────┘   └──────────┘            │
│       │               │                                 │
│  ─────────── Istio strict mTLS ──────────────           │
│                                                         │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐            │
│  │Prometheus│   │ Grafana  │   │  Jaeger  │            │
│  │ metrics  │   │dashboard │   │ tracing  │            │
│  └──────────┘   └──────────┘   └──────────┘            │
│                                                         │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐            │
│  │   OPA    │   │  Kiali   │   │   MCP    │            │
│  │Gatekeeper│   │mesh view │   │AI agent  │            │
│  └──────────┘   └──────────┘   └──────────┘            │
└─────────────────────────────────────────────────────────┘
```

---

## Services & Local URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| ArgoCD (GitOps UI) | http://localhost:8080 | admin / see script output |
| Jenkins (CI) | http://localhost:8888 | admin / admin123 |
| Vault (Secrets) | http://localhost:8200 | token: root |
| Grafana (Dashboards) | http://localhost:3000 | admin / admin |
| Prometheus (Metrics) | http://localhost:9090 | — |
| Jaeger (Tracing) | http://localhost:16686 | — |
| Kiali (Mesh) | http://localhost:20001 | — |

---

## Stack

| Layer | Technology |
|-------|-----------|
| Orchestration | Kubernetes 1.35 (Docker Desktop) |
| Service Mesh | Istio 1.29 — strict mTLS |
| CI | Jenkins 2.x via Helm |
| GitOps CD | ArgoCD 3.3 — app-of-apps |
| Progressive Delivery | Harness CD SaaS Free + Delegate |
| Secrets | HashiCorp Vault 1.17 — K8s auth |
| Policy | OPA Gatekeeper 3.14 — Rego |
| Metrics | Prometheus + Grafana |
| Tracing | Jaeger (OpenTelemetry) |
| Mesh Observability | Kiali |
| ML Serving | FastAPI + scikit-learn |
| Drift Detection | Evidently AI |
| AI Agent | MCP server (Claude API) |
| IaC | Terraform (AWS/GCP modules) |

---

## Quick Start

```bash
# 1. Enable Kubernetes in Docker Desktop, then:
./scripts/00-preflight-check.sh
./scripts/01-install-tools.sh
./scripts/02-setup-kubernetes.sh
./scripts/03-install-istio.sh
./scripts/04-install-vault.sh
./scripts/05-install-jenkins.sh
./scripts/06-install-argocd.sh
./scripts/07-install-opa-gatekeeper.sh
./scripts/08-install-observability.sh

# 2. Deploy apps via ArgoCD
kubectl apply -f argocd/app-of-apps.yaml

# 3. Open all UIs (run in separate terminals)
kubectl port-forward -n argocd       svc/argocd-server   8080:80   &
kubectl port-forward -n jenkins      svc/jenkins          8888:8080 &
kubectl port-forward -n vault        svc/vault            8200:8200 &
kubectl port-forward -n monitoring   svc/prometheus-grafana 3000:80 &
kubectl port-forward -n monitoring   svc/prometheus-kube-prometheus-prometheus 9090:9090 &
kubectl port-forward -n monitoring   svc/jaeger           16686:16686 &
kubectl port-forward -n istio-system svc/kiali            20001:20001 &
```

---

## Repository Layout

```
vertex-ai-gitops-platform/
├── scripts/          # 00-09 idempotent install scripts
├── apps/
│   ├── sample-app/   # FastAPI REST service
│   └── ml-model/     # scikit-learn inference + drift detection
├── helm/             # Helm charts (sample-app, ml-model, platform)
├── argocd/           # App-of-apps GitOps manifests
├── jenkins/          # Jenkinsfile (SAST→Snyk→Trivy→build→push)
├── harness/          # Harness pipeline YAML (canary + approval)
├── opa/              # OPA Gatekeeper ConstraintTemplates + Rego
├── terraform/        # Modules for AWS EKS + GCP GKE
├── grafana/          # Pre-built dashboard JSONs
├── evidently/        # Model drift detection configs
├── mcp/              # MCP AI agent server (auto incident response)
├── k8s/              # Namespaces, RBAC, NetworkPolicies
└── docs/             # LinkedIn post + interview talking points
```

---

## Key Design Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| GitOps engine | ArgoCD | Visual diff, sync waves, FS-friendly audit trail |
| Policy engine | OPA Gatekeeper | Rego unit-testable; maps to SR 11-7 model governance |
| Secret management | Vault K8s auth | Zero static credentials; pod identity-based |
| Service mesh | Istio strict mTLS | PRA in-transit encryption; Kiali topology |
| ML framework | scikit-learn | Tiny artefacts, ARM-native, framework-agnostic serving |
| AI agent | MCP server | Composable tool use; Claude Desktop + custom agent ready |

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Docker Desktop | 4.28+ | Enable Kubernetes in Settings |
| RAM allocated | ≥ 8 GB | Docker Desktop → Resources |
| Helm | 3.14+ | `brew install helm` |
| kubectl | 1.29+ | bundled with Docker Desktop |

---

---

## Live Demo Output

Both services run locally on Python 3.11. Below is **real captured output** from the
running services on Mac M1 / Docker Desktop Kubernetes.

### Sample App — `http://localhost:8000`

**`GET /health`**
```json
{
    "status": "ok",
    "version": "1.0.0",
    "uptime_seconds": 149.52
}
```

**`POST /predict`** — features `[2.5, 3.1, 1.8, 4.2, 0.9]`
```json
{
    "prediction": 2.5,
    "confidence": 0.25,
    "model_version": "v1.0.0",
    "request_id": "82d2b9e5-ae4c-4410-aa27-297395ac3bb6"
}
```

**`POST /predict`** — features `[-1.0, 0.5, 2.0, -3.0, 1.0]`
```json
{
    "prediction": -0.1,
    "confidence": 0.01,
    "model_version": "v1.0.0",
    "request_id": "7e2c9832-885e-4ab0-aad4-43c47b4d2a50"
}
```

---

### ML Model Service — `http://localhost:8001`

**`GET /health`** — RandomForest loaded, accuracy 89.25%
```json
{
    "status": "ok",
    "model_loaded": true,
    "model_version": "1.0.0",
    "accuracy": 0.8925,
    "uptime_seconds": 149.57
}
```

**`POST /predict`** — 10 real features → class 1 (62.3% confidence)
```json
{
    "prediction": 1,
    "probability": [0.3771, 0.6229],
    "model_version": "1.0.0",
    "request_id": "0752c351-6ea7-4cf3-9ca2-939817842f6b",
    "latency_ms": 6.81
}
```

**`POST /predict`** — different sample → class 1 (70.6% confidence)
```json
{
    "prediction": 1,
    "probability": [0.2935, 0.7065],
    "model_version": "1.0.0",
    "request_id": "68065d5d-51c1-40e8-af4c-ab16a4a2550a",
    "latency_ms": 2.78
}
```

**`GET /drift`** — Evidently AI drift monitor, no drift detected
```json
{
    "drift_score": 0.0,
    "threshold": 0.25,
    "drifted": false,
    "status": "healthy"
}
```

**`GET /metrics`** — Prometheus scrape (real output)
```
ml_model_predictions_total{label="1"} 2.0
ml_model_prediction_seconds_bucket{le="0.005"} 0.0
ml_model_prediction_seconds_bucket{le="0.01"}  0.0
ml_model_prediction_seconds_bucket{le="0.025"} 0.0
ml_model_prediction_seconds_bucket{le="0.05"}  0.0
ml_model_prediction_seconds_bucket{le="0.5"}   0.0
ml_model_accuracy 0.8925
ml_model_drift_score 0.0
```

---

### Platform Services Running on Kubernetes

```
NAMESPACE          SERVICE                                    STATUS
argocd             argocd-server                              Running  → http://localhost:8080
jenkins            jenkins                                    Running  → http://localhost:8888
vault              vault                                      Running  → http://localhost:8200
monitoring         prometheus-grafana                         Running  → http://localhost:3000
monitoring         prometheus-kube-prometheus-prometheus      Running  → http://localhost:9090
monitoring         jaeger                                     Running  → http://localhost:16686
istio-system       kiali                                      Running  → http://localhost:20001
gatekeeper-system  gatekeeper-controller-manager (×3)        Running  → admission webhook
istio-system       istiod                                     Running  → strict mTLS enforced
```

---

### GitHub Actions CI

Two automated test suites run on every push:

| Workflow | Test Case 1 | Test Case 2 |
|----------|-------------|-------------|
| **Sample App** | Health & Root endpoints | Predict & Metrics endpoints |
| **ML Model** | Model training artefact validation (accuracy > 80%) | Inference API schema validation |

---

## License

MIT — demonstration and portfolio use.
