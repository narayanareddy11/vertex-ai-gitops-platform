# Vertex AI GitOps Platform

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Kubernetes](https://img.shields.io/badge/kubernetes-1.35-326CE5?logo=kubernetes)
![Istio](https://img.shields.io/badge/istio-1.29-466BB0?logo=istio)
![ArgoCD](https://img.shields.io/badge/argocd-3.3-EF7B4D?logo=argo)
![Jenkins](https://img.shields.io/badge/jenkins-2.x-D24939?logo=jenkins)
![Vault](https://img.shields.io/badge/vault-1.17-FFEC6E?logo=vault)
![License](https://img.shields.io/badge/license-MIT-green)

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

## License

MIT — demonstration and portfolio use.
