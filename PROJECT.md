# Project Description

## Overview

**Vertex AI GitOps Platform** is an enterprise-grade, open-source reference platform
that demonstrates secure, governed, and observable AI/ML workload deployment on
Kubernetes using industry-standard GitOps practices.

It is built to mirror the platform engineering standards expected at tier-1 financial
institutions (Lloyds Banking Group, Barclays, Goldman Sachs) and AI infrastructure
companies (NVIDIA), combining DevSecOps, MLOps, and AI-assisted operations into a
single cohesive platform.

---

## Problem Statement

Deploying ML models in regulated industries (banking, finance, insurance) requires:

1. **Model governance** — who approved this model, what data was it trained on, what
   are its risk scores? Regulators (FCA, PRA) mandate this under SR 11-7 / SS1/23.
2. **Zero-trust networking** — all service-to-service traffic must be encrypted and
   authenticated. Static credentials are not acceptable.
3. **Auditable deployments** — every change must be traceable from a Git commit to a
   running pod. No manual `kubectl apply` in production.
4. **Canary safety** — ML models must be rolled out gradually with automated rollback
   on metric degradation.
5. **Drift detection** — models degrade silently. Production data distributions shift.
   Platform must detect and alert automatically.
6. **Autonomous incident response** — P1 incidents at 3 AM need an AI agent that can
   diagnose, roll back, and page the right human — not wake an engineer for a known
   bad deployment.

This platform solves all six problems.

---

## Goals

| Goal | Implementation |
|------|----------------|
| Secure model deployment | OPA Gatekeeper — model card required before pod schedules |
| Zero static secrets | HashiCorp Vault with Kubernetes pod-identity auth |
| Full auditability | ArgoCD GitOps — every cluster state tied to a Git commit SHA |
| Safe canary rollout | Harness CD with Prometheus verification + manual approval gate |
| Real-time drift detection | Evidently AI pushing metrics to Prometheus |
| Autonomous incident response | MCP AI agent with Kubernetes, Prometheus, Jaeger tools |
| mTLS everywhere | Istio strict PeerAuthentication cluster-wide |
| Supply chain security | Snyk SCA + Trivy CVE scan in every Jenkins pipeline run |

---

## Target Audience

### Engineers Building This

- Platform / MLOps engineers who want a complete, runnable local reference
- DevOps engineers moving into ML platform roles
- Software engineers preparing for senior roles at regulated institutions

### Roles This Targets

| Company | Role |
|---------|------|
| Lloyds Banking Group | ML Platform Engineer — model governance, FCA compliance |
| Barclays | Platform Engineering / MLOps — GitOps, canary, SLO tracking |
| Goldman Sachs | Quantitative Engineering / Strats — IaC, zero-trust, policy-as-code |
| NVIDIA | DevOps / MLOps Platform — GPU scheduling, AI agent tooling, MCP |

---

## Non-Goals

- This is **not** a production deployment. Dev-mode Vault, in-memory Jaeger, and
  single-node Kubernetes are intentionally used to minimise local resource use.
- This is **not** a cloud-only platform. Everything runs on a Mac M1 laptop.
  Terraform modules for AWS and GCP are provided for extensibility.
- This is **not** a specific ML problem solution. The scikit-learn model is a
  placeholder. The serving infrastructure is the point.

---

## How to Extend

| Extension | What to Change |
|-----------|---------------|
| Real ML model (PyTorch/TF) | Swap `apps/ml-model/Dockerfile` + `src/serve.py` |
| GPU workloads (NVIDIA) | Add `nodeSelector` + `tolerations` to `helm/ml-model/values.yaml` |
| Production Vault | Use `terraform/modules/vault` with HA Raft + AWS KMS auto-unseal |
| Cloud Kubernetes (EKS/GKE) | Apply `terraform/environments/aws` or `terraform/environments/gcp` |
| Real Harness pipeline | Set `HARNESS_DELEGATE_TOKEN` and run `scripts/09-install-harness-delegate.sh` |
| SBOM generation | Add Syft stage after Trivy in `jenkins/Jenkinsfile` |

---

## Author

**Venkata Narayana Reddy Mandhati**
Platform / MLOps Engineer

Built as a portfolio project demonstrating enterprise-grade GitOps and MLOps
patterns for senior engineering roles in financial services and AI infrastructure.
