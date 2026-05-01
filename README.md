# Vertex AI GitOps Platform

<div align="center">

[![Version](https://img.shields.io/badge/release-v1.0.0-blue?style=for-the-badge)](https://github.com/narayanareddy11/vertex-ai-gitops-platform/releases/tag/v1.0.0)
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](LICENSE)
[![Kubernetes](https://img.shields.io/badge/kubernetes-1.35-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io)
[![Python](https://img.shields.io/badge/python-3.11-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![Istio](https://img.shields.io/badge/istio-1.29-466BB0?style=for-the-badge&logo=istio&logoColor=white)](https://istio.io)
[![ArgoCD](https://img.shields.io/badge/argocd-3.3-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)](https://argoproj.github.io)
[![Jenkins](https://img.shields.io/badge/jenkins-2.x-D24939?style=for-the-badge&logo=jenkins&logoColor=white)](https://jenkins.io)
[![Vault](https://img.shields.io/badge/vault-1.17-FFEC6E?style=for-the-badge&logo=vault&logoColor=black)](https://vaultproject.io)
[![Terraform](https://img.shields.io/badge/terraform-1.7-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)](https://terraform.io)

[![Sample App Tests](https://github.com/narayanareddy11/vertex-ai-gitops-platform/actions/workflows/test-sample-app.yml/badge.svg)](https://github.com/narayanareddy11/vertex-ai-gitops-platform/actions/workflows/test-sample-app.yml)
[![ML Model Tests](https://github.com/narayanareddy11/vertex-ai-gitops-platform/actions/workflows/test-ml-model.yml/badge.svg)](https://github.com/narayanareddy11/vertex-ai-gitops-platform/actions/workflows/test-ml-model.yml)

</div>

---

## Description

**Vertex AI GitOps Platform** is an enterprise-grade, open-source MLOps and
GitOps reference platform that demonstrates secure, governed, and fully observable
AI/ML model deployment on Kubernetes.

It solves a real problem in regulated industries: **how do you deploy an ML model
into production at a bank — with full audit trail, zero static credentials, policy
enforcement, canary rollout, and automatic rollback — all as code?**

This platform implements all of that using 14 integrated open-source tools running
entirely on a Mac M1 laptop. Every component is production-pattern: the same
architecture used at **Lloyds Banking Group**, **Barclays**, **Goldman Sachs**,
and **NVIDIA** — just scaled down to run locally.

> Built by **Venkata Narayana Reddy Mandhati** as a portfolio project targeting
> senior Platform Engineer / MLOps Engineer roles in financial services and AI
> infrastructure.

---

## Tags & Topics

`kubernetes` `mlops` `gitops` `devops` `argocd` `jenkins` `istio` `vault`
`prometheus` `grafana` `jaeger` `kiali` `opa-gatekeeper` `terraform`
`fastapi` `scikit-learn` `evidently-ai` `harness` `mcp` `python`
`service-mesh` `mtls` `policy-as-code` `model-governance` `drift-detection`
`canary-deployment` `zero-trust` `devsecops` `fintech` `lloyds` `barclays`
`goldman-sachs` `nvidia` `docker` `helm` `platform-engineering`

---

## Technologies & Tools

### Orchestration & Infrastructure

| Tool | Version | Purpose |
|------|---------|---------|
| **Kubernetes** | 1.35 | Container orchestration — runs all platform services |
| **Docker Desktop** | 4.28+ | Local Kubernetes cluster on Mac M1 |
| **Helm** | 3.14 | Kubernetes package manager — deploys all services |
| **Terraform** | 1.7 | IaC modules for AWS EKS + GCP GKE extensibility |

### CI/CD & GitOps

| Tool | Version | Purpose |
|------|---------|---------|
| **Jenkins** | 2.x LTS | CI server — SAST, Snyk, Trivy, model-card gate, build, push |
| **ArgoCD** | 3.3.7 | GitOps engine — cluster auto-heals to match Git state |
| **Harness CD** | SaaS Free | Progressive delivery — canary rollout + manual approval gate |

### Security & Policy

| Tool | Version | Purpose |
|------|---------|---------|
| **Istio** | 1.29.2 | Service mesh — strict mTLS on all pod-to-pod traffic |
| **HashiCorp Vault** | 1.17.6 | Secrets management — dynamic credentials via K8s pod identity |
| **OPA Gatekeeper** | 3.14 | Policy engine — model card, resource limits, no-privileged enforcement |

### Observability

| Tool | Version | Purpose |
|------|---------|---------|
| **Prometheus** | 2.x | Metrics collection — scrapes all services + Istio |
| **Grafana** | 10.x | Dashboards — model monitoring, drift, platform overview |
| **Jaeger** | 2.17.0 | Distributed tracing — request journey across services |
| **Kiali** | 2.24.0 | Service mesh topology — live traffic + mTLS status |

### Applications & ML

| Tool | Version | Purpose |
|------|---------|---------|
| **FastAPI** | 0.111 | Sample REST service — `/health`, `/predict`, `/metrics` |
| **scikit-learn** | 1.4.2 | ML model — RandomForestClassifier (accuracy: 89.25%) |
| **Evidently AI** | 0.4.30 | Model drift detection — compares live vs training distributions |
| **Python** | 3.11 | All application and tooling code |

### AI & Automation

| Tool | Version | Purpose |
|------|---------|---------|
| **MCP Server** | Custom | AI agent — auto incident response (rollback, alert, RCA) |
| **Claude API** | Latest | Powers MCP agent tool use |

---

## Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                  Mac M1 · Docker Desktop Kubernetes                │
│                                                                    │
│   Git Push                                                         │
│      │                                                             │
│      ▼                                                             │
│  ┌─────────┐   SAST+Snyk+Trivy   ┌──────────┐   canary+gate      │
│  │ Jenkins │──── model card ────►│ Harness  │──────────────►     │
│  │   CI    │                     │    CD    │                     │
│  └─────────┘                     └──────────┘                     │
│      │                                │                           │
│      │ git commit                     │ deploy                    │
│      ▼                                ▼                           │
│  ┌─────────┐   auto-sync    ┌──────────────────┐                  │
│  │  ArgoCD │──────────────►│   K8s Cluster    │                  │
│  │  GitOps │               │                  │                  │
│  └─────────┘               │  ┌────────────┐  │                  │
│                            │  │ sample-app │  │ ← namespace:apps │
│  ┌─────────┐               │  │  FastAPI   │  │                  │
│  │  Vault  │ dynamic creds │  └─────┬──────┘  │                  │
│  │ Secrets │◄──────────────│        │ mTLS    │                  │
│  └─────────┘               │  ┌─────▼──────┐  │                  │
│                            │  │  ml-model  │  │ ← namespace:     │
│  ┌─────────┐               │  │  sklearn   │  │   ml-platform    │
│  │   OPA   │ admit/deny    │  └────────────┘  │                  │
│  │Gatekeeper◄─────────────│                  │                  │
│  └─────────┘               │  Istio mTLS everywhere              │
│                            └──────────────────┘                  │
│  ┌──────────────────────────────────────────────┐                 │
│  │  Prometheus · Grafana · Jaeger · Kiali       │                 │
│  │  Evidently drift detection (CronJob)         │                 │
│  │  MCP AI agent (auto rollback + RCA)          │                 │
│  └──────────────────────────────────────────────┘                 │
└────────────────────────────────────────────────────────────────────┘
```

---

## Services & Local URLs

| # | Service | URL | Credentials | Namespace |
|---|---------|-----|-------------|-----------|
| 1 | **ArgoCD** — GitOps UI | http://localhost:8080 | admin / *(script output)* | argocd |
| 2 | **Jenkins** — CI pipelines | http://localhost:8888 | admin / admin123 | jenkins |
| 3 | **Vault** — Secrets UI | http://localhost:8200 | token: `root` | vault |
| 4 | **Grafana** — Dashboards | http://localhost:3000 | admin / admin | monitoring |
| 5 | **Prometheus** — Metrics | http://localhost:9090 | — | monitoring |
| 6 | **Jaeger** — Tracing | http://localhost:16686 | — | monitoring |
| 7 | **Kiali** — Mesh topology | http://localhost:20001 | — | istio-system |
| 8 | **sample-app** — FastAPI | http://localhost:8000 | — | apps |
| 9 | **ml-model** — Inference | http://localhost:8001 | — | ml-platform |

---

## Quick Start

```bash
# Clone
git clone https://github.com/narayanareddy11/vertex-ai-gitops-platform.git
cd vertex-ai-gitops-platform

# 1. Enable Kubernetes: Docker Desktop → Settings → Kubernetes → Enable → Apply & Restart

# 2. Run install scripts in order (each is idempotent — safe to re-run)
./scripts/00-preflight-check.sh       # validate environment
./scripts/01-install-tools.sh         # install helm, argocd, vault, opa, trivy ...
./scripts/02-setup-kubernetes.sh      # namespaces + NetworkPolicies
./scripts/03-install-istio.sh         # service mesh + strict mTLS
./scripts/04-install-vault.sh         # secrets management
./scripts/05-install-jenkins.sh       # CI server
./scripts/06-install-argocd.sh        # GitOps engine
./scripts/07-install-opa-gatekeeper.sh # policy enforcement
./scripts/08-install-observability.sh  # Prometheus + Grafana + Jaeger + Kiali

# 3. Open all UIs
kubectl port-forward -n argocd       svc/argocd-server                         8080:80     &
kubectl port-forward -n jenkins      svc/jenkins                               8888:8080   &
kubectl port-forward -n vault        svc/vault                                 8200:8200   &
kubectl port-forward -n monitoring   svc/prometheus-grafana                    3000:80     &
kubectl port-forward -n monitoring   svc/prometheus-kube-prometheus-prometheus 9090:9090   &
kubectl port-forward -n monitoring   svc/jaeger                                16686:16686 &
kubectl port-forward -n istio-system svc/kiali                                 20001:20001 &

# 4. Run applications locally
/opt/homebrew/bin/python3.11 -m venv .venv && source .venv/bin/activate
pip install fastapi uvicorn pydantic prometheus-client scikit-learn joblib numpy httpx
uvicorn apps.sample-app.src.main:app --port 8000 &
uvicorn apps.ml-model.src.serve:app  --port 8001 &
```

---

## Live Demo Output

Real API responses captured from running services on Mac M1.

### Sample App — `http://localhost:8000`

```bash
curl http://localhost:8000/health
```
```json
{ "status": "ok", "version": "1.0.0", "uptime_seconds": 149.52 }
```

```bash
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"features": [2.5, 3.1, 1.8, 4.2, 0.9]}'
```
```json
{
  "prediction": 2.5,
  "confidence": 0.25,
  "model_version": "v1.0.0",
  "request_id": "82d2b9e5-ae4c-4410-aa27-297395ac3bb6"
}
```

### ML Model — `http://localhost:8001`

```bash
curl http://localhost:8001/health
```
```json
{
  "status": "ok",
  "model_loaded": true,
  "model_version": "1.0.0",
  "accuracy": 0.8925,
  "uptime_seconds": 149.57
}
```

```bash
curl -X POST http://localhost:8001/predict \
  -H "Content-Type: application/json" \
  -d '{"features": [1.2, -0.5, 2.3, 0.8, -1.1, 0.4, 1.7, -0.9, 0.3, 1.5]}'
```
```json
{
  "prediction": 1,
  "probability": [0.3771, 0.6229],
  "model_version": "1.0.0",
  "request_id": "0752c351-6ea7-4cf3-9ca2-939817842f6b",
  "latency_ms": 6.81
}
```

```bash
curl http://localhost:8001/drift
```
```json
{ "drift_score": 0.0, "threshold": 0.25, "drifted": false, "status": "healthy" }
```

---

## Repository Layout

```
vertex-ai-gitops-platform/
├── LICENSE                       ← MIT License
├── README.md                     ← This file
├── GUIDE.md                      ← Full end-to-end installation guide
├── CHANGELOG.md                  ← Version history
├── SERVICES.md                   ← All services with versions + URLs
├── PROJECT.md                    ← Problem statement + goals
├── ARCHITECTURE.md               ← 9 ADRs + design decisions
├── VERSION                       ← 1.0.0
│
├── scripts/                      ← Idempotent install scripts
│   ├── 00-preflight-check.sh
│   ├── 01-install-tools.sh
│   ├── 02-setup-kubernetes.sh
│   ├── 03-install-istio.sh
│   ├── 04-install-vault.sh
│   ├── 05-install-jenkins.sh
│   ├── 06-install-argocd.sh
│   ├── 07-install-opa-gatekeeper.sh
│   ├── 08-install-observability.sh
│   └── 09-install-harness-delegate.sh
│
├── apps/
│   ├── sample-app/               ← FastAPI REST service (port 8000)
│   │   ├── src/main.py           ← /health /predict /metrics endpoints
│   │   ├── src/models.py         ← Pydantic schemas
│   │   ├── tests/test_main.py    ← 5 unit tests
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── model-card.yaml       ← FCA SR11-7 compliance card
│   │
│   └── ml-model/                 ← scikit-learn inference (port 8001)
│       ├── src/train.py          ← RandomForest training (acc: 89.25%)
│       ├── src/serve.py          ← /health /predict /drift /metrics
│       ├── src/drift.py          ← Evidently AI drift detection
│       ├── models/metadata.json  ← trained model metadata
│       ├── tests/test_serve.py
│       ├── Dockerfile
│       └── model-card.yaml       ← FCA SS1/23 + GDPR compliant
│
├── helm/                         ← Helm charts
│   ├── sample-app/               ← HPA, PDB, ServiceMonitor, Istio
│   └── ml-model/                 ← HPA, resource limits, model-card
│
├── argocd/                       ← App-of-apps GitOps manifests
├── jenkins/                      ← Jenkinsfile CI pipeline
├── harness/                      ← Canary + approval gate pipeline
├── opa/                          ← Rego policies + ConstraintTemplates
├── terraform/                    ← AWS EKS + GCP GKE modules
├── grafana/                      ← Dashboard JSON files
├── evidently/                    ← Drift detection configs
├── mcp/                          ← MCP AI agent server
├── k8s/                          ← Raw Kubernetes manifests
└── .github/workflows/            ← GitHub Actions CI
    ├── test-sample-app.yml
    └── test-ml-model.yml
```

---

## Key Design Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| GitOps engine | ArgoCD | Visual diff, sync waves, FS-friendly audit trail |
| Policy engine | OPA Gatekeeper | Rego unit-testable; maps to FCA SR 11-7 model governance |
| Secret management | Vault K8s auth | Zero static credentials; pod identity-based dynamic secrets |
| Service mesh | Istio strict mTLS | PRA in-transit encryption; Kiali topology for compliance |
| ML framework | scikit-learn | ARM-native, tiny artefacts, framework-agnostic serving pattern |
| AI agent | MCP server | Composable tool use; Claude Desktop + custom agent compatible |
| CI | Jenkins on K8s | Ephemeral agents; FS-standard toolchain; air-gap capable |
| CD | Harness Free | Canary verification + approval gate; agent-based (no inbound firewall) |

---

## Target Roles

| Company | Role | Platform Relevance |
|---------|------|--------------------|
| **Lloyds Banking Group** | ML Platform Engineer | OPA model governance maps to FCA SR 11-7 / SS1/23 |
| **Barclays** | Platform Engineering / MLOps | GitOps audit trail satisfies PRA Change Management |
| **Goldman Sachs** | Quantitative Engineering / Strats | Vault + Istio zero-trust; Terraform IaC; OPA policy-as-code |
| **NVIDIA** | DevOps / MLOps Platform | MCP AI agent; multi-arch Docker; GPU-extensible Helm values |

---

## Prerequisites

| Requirement | Minimum | Notes |
|------------|---------|-------|
| Mac chip | Apple M1 | M2 / M3 also supported |
| RAM | 16 GB | Allocate 10 GB to Docker Desktop |
| Docker Desktop | 4.28+ | Enable Kubernetes in Settings |
| Python | 3.11 | `brew install python@3.11` |
| Disk | 20 GB free | Images + Helm charts |

---

## Release History

| Version | Date | Description |
|---------|------|-------------|
| **v1.0.0** | 2026-04-19 | Initial release — 9 services, 10 install scripts, 2 apps |

See [CHANGELOG.md](CHANGELOG.md) for full details.

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Commit your changes: `git commit -m 'feat: add my feature'`
4. Push to the branch: `git push origin feat/my-feature`
5. Open a Pull Request

---

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

Copyright © 2026 **Venkata Narayana Reddy Mandhati**

---

<div align="center">

**⭐ Star this repo if it helped you — and good luck with the interviews!**

[View Release v1.0.0](https://github.com/narayanareddy11/vertex-ai-gitops-platform/releases/tag/v1.0.0) ·
[Read the Guide](GUIDE.md) ·
[View Changelog](CHANGELOG.md) ·
[Report an Issue](https://github.com/narayanareddy11/vertex-ai-gitops-platform/issues)

</div>
