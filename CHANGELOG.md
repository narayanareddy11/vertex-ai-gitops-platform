# Changelog

All notable changes to the Vertex AI GitOps Platform are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] — 2026-04-19

### Added

#### Platform Bootstrap
- `scripts/00-preflight-check.sh` — validates Kubernetes, RAM, disk, and CLI tools before install
- `scripts/01-install-tools.sh` — idempotent install of helm, argocd, istioctl, vault, opa, terraform, snyk, trivy; adds all Helm repos
- `scripts/02-setup-kubernetes.sh` — namespaces (apps, ml-platform, vault, jenkins, argocd, monitoring, istio-system, gatekeeper-system), default-deny NetworkPolicies, Istio injection labels

#### Service Mesh
- `scripts/03-install-istio.sh` — Istio 1.29.2 (base + istiod + ingress gateway) with cluster-wide strict mTLS PeerAuthentication

#### Secrets Management
- `scripts/04-install-vault.sh` — HashiCorp Vault 1.17.6 dev mode; Kubernetes auth backend with roles for apps, ml-platform, jenkins; seeded demo secrets

#### CI/CD
- `scripts/05-install-jenkins.sh` — Jenkins 2.x via Helm with Kubernetes agent, Git, BlueOcean, Docker Workflow, Snyk plugins
- `scripts/06-install-argocd.sh` — ArgoCD 3.3.7 with CLI login and docker-desktop cluster registration

#### Policy Engine
- `scripts/07-install-opa-gatekeeper.sh` — OPA Gatekeeper 3.14 with three ConstraintTemplates:
  - `RequireModelCard` — blocks ML pods without `ai.platform/model-card` annotation
  - `RequireResourceLimits` — enforces CPU/memory limits on all containers
  - `DenyPrivilegedContainers` — blocks privileged pod escalation

#### Observability
- `scripts/08-install-observability.sh` — kube-prometheus-stack (Prometheus + Grafana), Jaeger 2.17.0, Kiali 2.24.0; Istio telemetry integration

#### Harness CD
- `scripts/09-install-harness-delegate.sh` — Harness Delegate deployment (token-gated; graceful skip if not configured)

#### Documentation
- `README.md` — clear architecture diagram, service URLs, stack table, quick-start guide
- `PROJECT.md` — problem statement, goals, target audience, extension guide
- `SERVICES.md` — full service inventory with versions, namespaces, port-forward commands
- `ARCHITECTURE.md` — 9 Architecture Decision Records mapping every tool choice to interview talking points
- `VERSION` — machine-readable version file
- `CHANGELOG.md` — this file

#### Repository Structure
- Full directory skeleton: `apps/`, `helm/`, `argocd/`, `jenkins/`, `harness/`, `opa/`, `terraform/`, `grafana/`, `evidently/`, `mcp/`, `k8s/`, `docs/`
- `.gitignore` covering Python, Terraform state, ML artefacts, secrets

### Platform Versions (v1.0.0)

| Component | Version |
|-----------|---------|
| Kubernetes | 1.35.1 |
| Istio | 1.29.2 |
| ArgoCD | 3.3.7 |
| Jenkins | 2.x LTS |
| HashiCorp Vault | 1.17.6 |
| OPA Gatekeeper | 3.14.x |
| Prometheus | 2.x |
| Grafana | 10.x |
| Jaeger | 2.17.0 |
| Kiali | 2.24.0 |

---

## [Unreleased]

### Planned for v1.1.0
- FastAPI sample-app source code + Dockerfile
- scikit-learn ml-model inference service + Evidently AI drift detection
- Helm charts for sample-app and ml-model
- ArgoCD app-of-apps manifests
- Jenkinsfile (SAST → Snyk → Trivy → model-card → build → push)
- Harness pipeline YAML (canary + approval gate)
- Grafana dashboard JSONs (4 pre-built dashboards)
- MCP AI agent server with Prometheus, Jaeger, Kubernetes, incident tools
- Terraform modules (AWS EKS + GCP GKE)
- docs/linkedin-post.md + docs/interview-talking-points.md
