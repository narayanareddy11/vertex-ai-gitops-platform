# Release v1.0.0 — Initial Platform Release

**Released:** 2026-04-19
**Tag:** `v1.0.0`
**Branch:** `main`

---

## Release Summary

This is the first stable release of the **Vertex AI GitOps Platform** — a fully
bootstrapped, locally runnable enterprise MLOps platform with 9 integrated services.

---

## What's Included

### 9 Running Services

| # | Service | Version | URL |
|---|---------|---------|-----|
| 1 | ArgoCD | 3.3.7 | http://localhost:8080 |
| 2 | Jenkins | 2.x LTS | http://localhost:8888 |
| 3 | HashiCorp Vault | 1.17.6 | http://localhost:8200 |
| 4 | Prometheus | 2.x | http://localhost:9090 |
| 5 | Grafana | 10.x | http://localhost:3000 |
| 6 | Jaeger | 2.17.0 | http://localhost:16686 |
| 7 | Kiali | 2.24.0 | http://localhost:20001 |
| 8 | Istio | 1.29.2 | *(mesh — no UI)* |
| 9 | OPA Gatekeeper | 3.14.x | *(admission webhook)* |

### 10 Bootstrap Scripts

| Script | Purpose |
|--------|---------|
| `00-preflight-check.sh` | Validate environment |
| `01-install-tools.sh` | Install all CLI tools + Helm repos |
| `02-setup-kubernetes.sh` | Namespaces, NetworkPolicies, labels |
| `03-install-istio.sh` | Istio + strict mTLS |
| `04-install-vault.sh` | Vault dev mode + K8s auth |
| `05-install-jenkins.sh` | Jenkins CI via Helm |
| `06-install-argocd.sh` | ArgoCD GitOps engine |
| `07-install-opa-gatekeeper.sh` | OPA policy enforcement |
| `08-install-observability.sh` | Prometheus + Grafana + Jaeger + Kiali |
| `09-install-harness-delegate.sh` | Harness CD delegate (optional) |

### Security Posture
- Strict mTLS across all namespaces via Istio PeerAuthentication
- Zero static secrets — Vault K8s pod-identity auth only
- OPA model governance: RequireModelCard + DenyPrivilegedContainers + RequireResourceLimits
- Default-deny NetworkPolicies on `apps` and `ml-platform` namespaces

---

## How to Install

```bash
git clone https://github.com/narayanareddy11/vertex-ai-gitops-platform.git
cd vertex-ai-gitops-platform
git checkout v1.0.0
for i in $(seq 0 8); do
  printf -v n "%02d" $i
  script=$(ls scripts/${n}-*.sh)
  echo "Running $script..."
  bash "$script"
done
```

---

## Known Limitations (v1.0.0)

- Vault runs in dev mode — secrets lost on pod restart
- Jaeger uses in-memory storage — traces lost on pod restart
- Harness Delegate requires a separate free account at app.harness.io
- Application source code (FastAPI, ml-model) planned for v1.1.0

---

## Next Release: v1.1.0

- Application source code (FastAPI sample-app + scikit-learn ml-model)
- Helm charts + ArgoCD app deployments
- Jenkinsfile CI pipeline
- Harness canary pipeline YAML
- Grafana dashboard JSON files
- MCP AI agent server
