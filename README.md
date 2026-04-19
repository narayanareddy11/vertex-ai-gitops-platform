# Vertex AI GitOps Platform

> **Enterprise-grade AI-safe GitOps platform** demonstrating production-ready ML model lifecycle
> management with full observability, policy enforcement, and autonomous incident response.
> Targeted at senior platform/MLOps engineering roles at **Lloyds Banking Group**, **Barclays**,
> **Goldman Sachs**, and **NVIDIA**.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         DEVELOPER WORKSTATION (Mac M1 / 16 GB)                  │
│                         Docker Desktop Kubernetes (local cluster)                │
└─────────────────────────────────────────────────────────────────────────────────┘
                                        │
                    ┌───────────────────▼──────────────────────┐
                    │           SOURCE CONTROL (Git)            │
                    │   GitHub / GitLab (this repository)       │
                    └───────────┬──────────────────┬───────────┘
                                │                  │
              ┌─────────────────▼──┐      ┌────────▼────────────┐
              │   CI: Jenkins       │      │   CD: ArgoCD        │
              │   (Helm, k8s)       │      │   (GitOps pull)     │
              │                     │      │   App-of-Apps       │
              │  Stages:            │      │                     │
              │  1. SAST (Bandit)   │      │  Watches:           │
              │  2. Snyk SCA        │      │  • sample-app       │
              │  3. Trivy image scan│      │  • ml-model         │
              │  4. Model Card check│      │  • platform infra   │
              │  5. Build & push    │      └────────┬────────────┘
              │  6. Notify Harness  │               │
              └─────────┬───────────┘               │
                        │                           │
              ┌─────────▼───────────────────────────▼───────────┐
              │              Harness CD (SaaS Free + Delegate)   │
              │   Canary Deployment → Approval Gate → Promote    │
              └─────────────────────────┬───────────────────────┘
                                        │
    ┌───────────────────────────────────▼──────────────────────────────────────┐
    │                    KUBERNETES CLUSTER (docker-desktop)                    │
    │                                                                           │
    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
    │  │  NAMESPACE:  │  │  NAMESPACE:  │  │  NAMESPACE:  │  │  NAMESPACE:  │ │
    │  │  apps        │  │  ml-platform │  │  istio-system│  │  monitoring  │ │
    │  │              │  │              │  │              │  │              │ │
    │  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │ │
    │  │ │sample-app│ │  │ │ml-model  │ │  │ │  Istio   │ │  │ │Prometheus│ │ │
    │  │ │(FastAPI) │ │  │ │(sklearn) │ │  │ │  Pilot   │ │  │ │          │ │ │
    │  │ └────┬─────┘ │  │ └────┬─────┘ │  │ └──────────┘ │  │ └──────────┘ │ │
    │  │      │mTLS   │  │      │mTLS   │  │              │  │ ┌──────────┐ │ │
    │  │ ┌────▼─────┐ │  │ ┌────▼─────┐ │  │ ┌──────────┐ │  │ │ Grafana  │ │ │
    │  │ │ Envoy    │ │  │ │ Envoy    │ │  │ │  Kiali   │ │  │ └──────────┘ │ │
    │  │ │ sidecar  │ │  │ │ sidecar  │ │  │ └──────────┘ │  │ ┌──────────┐ │ │
    │  │ └──────────┘ │  │ └──────────┘ │  │              │  │ │  Jaeger  │ │ │
    │  └──────────────┘  └──────────────┘  └──────────────┘  │ └──────────┘ │ │
    │                                                          └──────────────┘ │
    │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
    │  │  NAMESPACE:  │  │  NAMESPACE:  │  │  NAMESPACE:  │  │  NAMESPACE:  │ │
    │  │  vault       │  │  argocd      │  │  jenkins     │  │  gatekeeper  │ │
    │  │              │  │              │  │              │  │  -system     │ │
    │  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │ │
    │  │ │ HashiCorp│ │  │ │  ArgoCD  │ │  │ │ Jenkins  │ │  │ │   OPA    │ │ │
    │  │ │  Vault   │ │  │ │  Server  │ │  │ │  (Helm)  │ │  │ │Gatekeeper│ │ │
    │  │ │ (dev)    │ │  │ │          │ │  │ └──────────┘ │  │ └──────────┘ │ │
    │  │ └──────────┘ │  │ └──────────┘ │  └──────────────┘  └──────────────┘ │
    │  └──────────────┘  └──────────────┘                                      │
    │                                                                           │
    │  ┌──────────────────────────────────────────────────────────────────────┐ │
    │  │                    ISTIO SERVICE MESH                                 │ │
    │  │         Strict mTLS  |  Traffic Management  |  Authorization Policy  │ │
    │  └──────────────────────────────────────────────────────────────────────┘ │
    └───────────────────────────────────────────────────────────────────────────┘
                                        │
                    ┌───────────────────▼──────────────────────┐
                    │            MCP AI AGENT SERVER            │
                    │    (Python, Claude API / OpenAI)          │
                    │                                           │
                    │  Tools:                                   │
                    │  • query_prometheus()  → detect anomalies │
                    │  • get_jaeger_traces() → root cause       │
                    │  • rollback_deployment() → auto-heal      │
                    │  • create_incident_ticket()               │
                    │  • notify_slack()                         │
                    │  • check_model_drift() → Evidently AI     │
                    └───────────────────────────────────────────┘
```

---

## Repository Layout

```
vertex-ai-gitops-platform/
│
├── README.md                          ← You are here
├── ARCHITECTURE.md                    ← Deep-dive design decisions
│
├── scripts/                           ← Idempotent install scripts (run in order)
│   ├── 00-preflight-check.sh          ← Validate tools, RAM, k8s context
│   ├── 01-install-tools.sh            ← brew: helm, argocd, vault, istioctl, etc.
│   ├── 02-setup-kubernetes.sh         ← Namespaces, RBAC, NetworkPolicies
│   ├── 03-install-istio.sh            ← Istio with strict mTLS PeerAuthentication
│   ├── 04-install-vault.sh            ← Vault dev mode + k8s auth backend
│   ├── 05-install-jenkins.sh          ← Jenkins via Helm (jenkins/jenkins chart)
│   ├── 06-install-argocd.sh           ← ArgoCD + app-of-apps bootstrap
│   ├── 07-install-opa-gatekeeper.sh   ← OPA Gatekeeper + constraint templates
│   ├── 08-install-observability.sh    ← Prometheus, Grafana, Jaeger, Kiali
│   └── 09-install-harness-delegate.sh ← Harness Delegate + Kubernetes connector
│
├── apps/                              ← Application source code
│   ├── sample-app/                    ← FastAPI REST service
│   │   ├── src/
│   │   │   ├── main.py                ← FastAPI app with /health, /predict endpoints
│   │   │   ├── middleware.py          ← Prometheus metrics, trace propagation
│   │   │   └── models.py             ← Pydantic schemas
│   │   ├── tests/
│   │   │   └── test_main.py
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── model-card.yaml           ← Model Card for OPA gate check
│   │
│   └── ml-model/                      ← scikit-learn inference service
│       ├── src/
│       │   ├── train.py               ← Model training script
│       │   ├── serve.py               ← FastAPI inference server
│       │   └── drift.py               ← Evidently AI drift detection
│       ├── tests/
│       │   └── test_serve.py
│       ├── models/                    ← Serialised model artefacts (.joblib)
│       ├── Dockerfile
│       ├── requirements.txt
│       └── model-card.yaml
│
├── helm/                              ← Helm charts
│   ├── sample-app/
│   │   ├── Chart.yaml
│   │   ├── values.yaml                ← Default values
│   │   ├── values-prod.yaml           ← Production overrides
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── hpa.yaml
│   │       ├── pdb.yaml
│   │       ├── servicemonitor.yaml    ← Prometheus scrape config
│   │       ├── destinationrule.yaml   ← Istio circuit breaker
│   │       └── virtualservice.yaml    ← Istio traffic split (canary)
│   │
│   ├── ml-model/
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   ├── values-prod.yaml
│   │   └── templates/
│   │       ├── deployment.yaml
│   │       ├── service.yaml
│   │       ├── hpa.yaml
│   │       ├── pdb.yaml
│   │       ├── servicemonitor.yaml
│   │       ├── destinationrule.yaml
│   │       └── virtualservice.yaml
│   │
│   └── platform/                      ← Umbrella chart (optional)
│       ├── Chart.yaml
│       └── templates/
│
├── argocd/                            ← ArgoCD manifests
│   ├── app-of-apps.yaml               ← Root Application (points to /argocd/applications/)
│   └── applications/
│       ├── sample-app.yaml
│       ├── ml-model.yaml
│       ├── monitoring.yaml
│       ├── vault.yaml
│       └── gatekeeper.yaml
│
├── jenkins/
│   └── Jenkinsfile                    ← Pipeline: SAST→Snyk→Trivy→model-card→build→push
│
├── harness/
│   └── pipeline.yaml                  ← Harness CD: canary + manual approval gate
│
├── opa/
│   ├── constraints/
│   │   ├── require-model-card.yaml           ← All ML pods must have model-card annotation
│   │   ├── require-resource-limits.yaml       ← CPU/memory limits mandatory
│   │   ├── deny-privileged-containers.yaml    ← No privileged pods
│   │   └── require-approved-registries.yaml   ← Only trusted image registries
│   └── policies/
│       ├── model-approval.rego                ← Model governance Rego policy
│       └── image-registry.rego
│
├── terraform/                         ← IaC (cloud-equivalent, AWS/GCP ready)
│   ├── modules/
│   │   ├── vault/                     ← Vault cluster module
│   │   ├── networking/                ← VPC, subnets, security groups
│   │   └── monitoring/                ← Managed Prometheus / CloudWatch
│   └── environments/
│       ├── local/                     ← docker-desktop (no-op / reference)
│       ├── aws/                       ← EKS + RDS + MSK
│       └── gcp/                       ← GKE + AlloyDB (Vertex AI ready)
│
├── grafana/
│   └── dashboards/
│       ├── ml-model-monitoring.json   ← Prediction latency, throughput, error rate
│       ├── model-drift.json           ← Evidently AI metrics pushed to Prometheus
│       ├── platform-overview.json     ← Cluster health + GitOps sync status
│       └── canary-analysis.json       ← Canary vs stable traffic split
│
├── evidently/
│   ├── configs/
│   │   └── drift-config.yaml          ← Feature drift thresholds
│   └── reports/                       ← Generated HTML/JSON drift reports
│
├── mcp/
│   ├── server.py                      ← MCP server: AI DevOps agent tools
│   ├── tools/
│   │   ├── prometheus.py              ← query_prometheus tool
│   │   ├── jaeger.py                  ← get_jaeger_traces tool
│   │   ├── kubernetes.py              ← rollback_deployment, scale_deployment
│   │   ├── evidently.py               ← check_model_drift tool
│   │   └── incident.py                ← create_incident_ticket, notify_slack
│   ├── requirements.txt
│   └── README.md
│
├── k8s/                               ← Raw Kubernetes manifests
│   ├── namespaces/
│   │   └── namespaces.yaml
│   ├── rbac/
│   │   └── rbac.yaml
│   └── networkpolicies/
│       └── default-deny.yaml
│
└── docs/
    ├── linkedin-post.md               ← Ready-to-publish LinkedIn article
    └── interview-talking-points.md    ← Structured prep for target companies
```

---

## Component Details

### CI/CD Pipeline

| Stage | Tool | What It Does |
|-------|------|--------------|
| SAST | Bandit | Static analysis of Python source for security issues |
| SCA | Snyk | Dependency vulnerability scan (`requirements.txt`) |
| Container Scan | Trivy | Image CVE scan; blocks on CRITICAL findings |
| Model Card Gate | OPA/curl | Validates `model-card.yaml` against governance schema |
| Build | Docker (Buildx) | Multi-arch image for linux/arm64 (M1 native) |
| Push | Docker Hub / ECR | Pushes tagged image; updates Helm `values.yaml` |
| Notify | Harness webhook | Triggers Harness pipeline for CD |

### GitOps with ArgoCD (App-of-Apps)

```
argocd/app-of-apps.yaml                 ← Root app
  └── argocd/applications/
        ├── sample-app.yaml             → helm/sample-app/  (namespace: apps)
        ├── ml-model.yaml               → helm/ml-model/    (namespace: ml-platform)
        ├── monitoring.yaml             → kube-prometheus-stack
        ├── vault.yaml                  → vault helm chart
        └── gatekeeper.yaml             → OPA Gatekeeper
```

ArgoCD reconciles every 3 minutes. Any drift from Git is auto-healed (apps) or
alerted (infra). Sync waves ensure Vault and Gatekeeper are ready before apps.

### Harness CD Canary Strategy

```
Deploy 10% canary
  → Wait 5 min (Prometheus: error_rate < 1%, p99 < 500ms)
  → Manual approval gate (Slack notification)
  → Promote to 50%
  → Wait 5 min
  → Promote to 100%
  → Cleanup canary pods
```

### Vault Secret Injection

All app pods use the Vault Agent Injector sidecar. Secrets are projected into
`/vault/secrets/` as env-file format. K8s auth backend authenticates pods via
their ServiceAccount tokens — no static credentials anywhere.

### OPA Gatekeeper Policies

| Constraint | Enforcement | Rationale |
|-----------|-------------|-----------|
| `require-model-card` | deny | Every ML workload must declare a model card |
| `require-resource-limits` | deny | Prevents resource starvation (FSS/FCA requirement) |
| `deny-privileged` | deny | Zero-trust pod security |
| `approved-registries` | deny | Supply chain security; only `docker.io/yourorg`, ECR, GCR |

### Observability Stack

| Tool | Purpose | Access |
|------|---------|--------|
| Prometheus | Metrics collection + alerting | `kubectl port-forward svc/prometheus 9090` |
| Grafana | Dashboards (4 pre-built) | `kubectl port-forward svc/grafana 3000` |
| Jaeger | Distributed tracing (OpenTelemetry) | `kubectl port-forward svc/jaeger-query 16686` |
| Kiali | Service mesh topology | `kubectl port-forward svc/kiali 20001` |
| Evidently AI | Model drift detection | HTML reports + Prometheus push |

### MCP AI Agent (Auto Incident Response)

The MCP server exposes DevOps tools to any MCP-compatible AI client (Claude Desktop,
custom agents). On a P1 alert, the agent:

1. Calls `query_prometheus()` → identifies anomalous metrics
2. Calls `get_jaeger_traces()` → finds error-causing spans
3. Decides: rollback vs scale vs page human
4. Calls `rollback_deployment()` or `scale_deployment()`
5. Calls `create_incident_ticket()` → PagerDuty / Jira
6. Calls `notify_slack()` → posts RCA summary

---

## Quick Start

```bash
# 1. Validate prerequisites
./scripts/00-preflight-check.sh

# 2. Install CLI tools (idempotent)
./scripts/01-install-tools.sh

# 3. Bootstrap the cluster
./scripts/02-setup-kubernetes.sh
./scripts/03-install-istio.sh
./scripts/04-install-vault.sh
./scripts/05-install-jenkins.sh
./scripts/06-install-argocd.sh
./scripts/07-install-opa-gatekeeper.sh
./scripts/08-install-observability.sh
./scripts/09-install-harness-delegate.sh

# 4. Deploy everything via ArgoCD
kubectl apply -f argocd/app-of-apps.yaml

# 5. Open dashboards
kubectl port-forward -n monitoring svc/grafana 3000:80 &
kubectl port-forward -n argocd svc/argocd-server 8080:443 &
kubectl port-forward -n istio-system svc/kiali 20001:20001 &
```

---

## Prerequisites

| Requirement | Minimum | Notes |
|------------|---------|-------|
| macOS | Sonoma 14+ | Apple Silicon (M1/M2/M3) |
| RAM | 16 GB | Allocate 10 GB to Docker Desktop |
| Docker Desktop | 4.28+ | Enable Kubernetes in Settings |
| Disk | 40 GB free | Images + Helm charts |
| Homebrew | Any | Package manager |

---

## Target Roles & Alignment

### Lloyds Banking Group — ML Platform Engineer
- OPA Gatekeeper policies map directly to FCA model risk management requirements
- Vault secret injection demonstrates banking-grade secret hygiene
- Evidently AI drift monitoring addresses SR 11-7 / SS1/23 model governance

### Barclays — Platform Engineering / MLOps
- GitOps with ArgoCD = auditability required by PRA/FCA Change Management rules
- Harness canary + approval gates = controlled deployment with human oversight
- Prometheus + Grafana dashboards = production model SLO tracking

### Goldman Sachs — Quantitative Engineering / Strats
- Istio strict mTLS = zero-trust network (Goldman's internal security posture)
- OPA policies as code = governance-as-code, auditable by Compliance
- Terraform modules = infrastructure reproducibility across regions

### NVIDIA — DevOps / MLOps Platform
- Sample ML workload extensible to GPU scheduling (add nodeSelector + tolerations)
- MCP AI agent demonstrates AI-assisted operations (NVIDIA's AI enterprise push)
- Multi-arch Docker builds (linux/arm64) show M1/GPU portability awareness

---

## Technology Stack Summary

```
Language:      Python 3.11 (FastAPI, scikit-learn, Evidently, MCP)
Container:     Docker Buildx (multi-arch: linux/arm64, linux/amd64)
Orchestration: Kubernetes 1.29 (Docker Desktop)
Service Mesh:  Istio 1.21 (strict mTLS, RBAC, traffic management)
Package Mgmt:  Helm 3.14
CI:            Jenkins 2.x (Helm chart, Kubernetes agent)
CD:            Harness SaaS Free + local Delegate
GitOps:        ArgoCD 2.10 (app-of-apps pattern)
Secrets:       HashiCorp Vault 1.15 (dev mode, K8s auth)
Policy:        OPA Gatekeeper 3.14 (Rego constraint templates)
Monitoring:    Prometheus 2.50 + Grafana 10.3 + Jaeger 1.55 + Kiali 1.82
ML Drift:      Evidently AI 0.4
IaC:           Terraform 1.7 (modules for AWS EKS + GCP GKE)
AI Agent:      MCP server (Claude API / OpenAI compatible)
```

---

## Security Posture

- **Zero static secrets** — all credentials via Vault dynamic secrets or K8s auth
- **mTLS everywhere** — Istio PeerAuthentication in STRICT mode cluster-wide
- **Least privilege RBAC** — dedicated ServiceAccounts per workload, no cluster-admin
- **Image signing** — Cosign integration (Jenkinsfile stage; verification via OPA)
- **Supply chain** — Snyk + Trivy in every pipeline run; SBOM generation
- **Network isolation** — default-deny NetworkPolicies; explicit allow-lists only
- **Admission control** — OPA Gatekeeper blocks non-compliant workloads at deploy time

---

## License

MIT — for demonstration and educational purposes.
Built to showcase enterprise MLOps patterns for interview portfolios.
