# Service Inventory — v1.0.0

All services deployed as part of the Vertex AI GitOps Platform v1.0.0.
Each entry includes the Helm chart version, container image tag, namespace,
and local access URL.

---

## Core Platform Services

### ArgoCD — GitOps Controller
| Property | Value |
|----------|-------|
| **Version** | 3.3.7 |
| **Helm Chart** | `argo/argo-cd` |
| **Namespace** | `argocd` |
| **Image** | `quay.io/argoproj/argocd:v3.3.7` |
| **Local URL** | http://localhost:8080 |
| **Port-forward** | `kubectl port-forward -n argocd svc/argocd-server 8080:80` |
| **Credentials** | admin / *(generated — see script 06 output)* |

---

### Jenkins — CI Server
| Property | Value |
|----------|-------|
| **Version** | 2.x (latest LTS) |
| **Helm Chart** | `jenkins/jenkins` |
| **Namespace** | `jenkins` |
| **Image** | `jenkins/jenkins:lts` |
| **Local URL** | http://localhost:8888 |
| **Port-forward** | `kubectl port-forward -n jenkins svc/jenkins 8888:8080` |
| **Credentials** | admin / admin123 |

---

### HashiCorp Vault — Secrets Management
| Property | Value |
|----------|-------|
| **Version** | 1.17.6 |
| **Helm Chart** | `hashicorp/vault` |
| **Namespace** | `vault` |
| **Image** | `hashicorp/vault:1.17.6` |
| **Mode** | Dev (root token = `root`) |
| **Local URL** | http://localhost:8200 |
| **Port-forward** | `kubectl port-forward -n vault svc/vault 8200:8200` |
| **K8s Auth** | Enabled — bound to `apps`, `ml-platform`, `jenkins` namespaces |

---

## Observability Services

### Prometheus — Metrics
| Property | Value |
|----------|-------|
| **Version** | 2.x (kube-prometheus-stack) |
| **Helm Chart** | `prometheus/kube-prometheus-stack` |
| **Namespace** | `monitoring` |
| **Retention** | 7 days |
| **Local URL** | http://localhost:9090 |
| **Port-forward** | `kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090` |

---

### Grafana — Dashboards
| Property | Value |
|----------|-------|
| **Version** | 10.x (bundled with kube-prometheus-stack) |
| **Namespace** | `monitoring` |
| **Local URL** | http://localhost:3000 |
| **Port-forward** | `kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80` |
| **Credentials** | admin / admin |
| **Dashboards** | ML Model Monitoring · Model Drift · Platform Overview · Canary Analysis |

---

### Jaeger — Distributed Tracing
| Property | Value |
|----------|-------|
| **Version** | 2.17.0 |
| **Helm Chart** | `jaeger/jaeger` |
| **Namespace** | `monitoring` |
| **Mode** | All-in-one (in-memory) |
| **Local URL** | http://localhost:16686 |
| **Port-forward** | `kubectl port-forward -n monitoring svc/jaeger 16686:16686` |

---

### Kiali — Service Mesh Topology
| Property | Value |
|----------|-------|
| **Version** | 2.24.0 |
| **Helm Chart** | `kiali/kiali-server` |
| **Namespace** | `istio-system` |
| **Auth** | Anonymous (local dev) |
| **Local URL** | http://localhost:20001 |
| **Port-forward** | `kubectl port-forward -n istio-system svc/kiali 20001:20001` |

---

## Security Services

### Istio — Service Mesh
| Property | Value |
|----------|-------|
| **Version** | 1.29.2 |
| **Helm Chart** | `istio/base` + `istio/istiod` + `istio/gateway` |
| **Namespace** | `istio-system` |
| **mTLS Mode** | STRICT (cluster-wide PeerAuthentication) |
| **Injection** | Enabled on `apps`, `ml-platform` namespaces |

---

### OPA Gatekeeper — Policy Engine
| Property | Value |
|----------|-------|
| **Version** | 3.14.x |
| **Helm Chart** | `open-policy-agent/gatekeeper` |
| **Namespace** | `gatekeeper-system` |
| **Constraints Active** | RequireModelCard · DenyPrivilegedContainers · RequireResourceLimits |
| **Enforcement** | `deny` on `apps` and `ml-platform` namespaces |

---

## Application Services *(deployed via ArgoCD)*

### sample-app — FastAPI REST Service
| Property | Value |
|----------|-------|
| **Version** | 1.0.0 |
| **Namespace** | `apps` |
| **Image** | `yourorg/sample-app:1.0.0` |
| **Local URL** | http://localhost:8000 *(after deploy)* |
| **Port-forward** | `kubectl port-forward -n apps svc/sample-app 8000:80` |
| **Endpoints** | `GET /health` · `POST /predict` · `GET /metrics` |

---

### ml-model — scikit-learn Inference Service
| Property | Value |
|----------|-------|
| **Version** | 1.0.0 |
| **Namespace** | `ml-platform` |
| **Image** | `yourorg/ml-model:1.0.0` |
| **Framework** | scikit-learn + Evidently AI drift detection |
| **Local URL** | http://localhost:8001 *(after deploy)* |
| **Port-forward** | `kubectl port-forward -n ml-platform svc/ml-model 8001:80` |
| **Endpoints** | `GET /health` · `POST /predict` · `GET /drift` · `GET /metrics` |

---

## Quick Access — All Port-Forwards at Once

```bash
kubectl port-forward -n argocd       svc/argocd-server                              8080:80    &
kubectl port-forward -n jenkins      svc/jenkins                                    8888:8080  &
kubectl port-forward -n vault        svc/vault                                      8200:8200  &
kubectl port-forward -n monitoring   svc/prometheus-grafana                         3000:80    &
kubectl port-forward -n monitoring   svc/prometheus-kube-prometheus-prometheus      9090:9090  &
kubectl port-forward -n monitoring   svc/jaeger                                     16686:16686 &
kubectl port-forward -n istio-system svc/kiali                                      20001:20001 &
```

---

## Namespace Summary

| Namespace | Services |
|-----------|---------|
| `argocd` | ArgoCD server, repo-server, app-controller, redis |
| `jenkins` | Jenkins controller + ephemeral agent pods |
| `vault` | Vault server + agent injector |
| `monitoring` | Prometheus, Grafana, Jaeger |
| `istio-system` | Istiod, ingress gateway, Kiali |
| `gatekeeper-system` | OPA controller (×3), audit pod |
| `apps` | sample-app (FastAPI) |
| `ml-platform` | ml-model (scikit-learn inference) |
