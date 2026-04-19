# Architecture Decision Records (ADRs)

This document captures the key design decisions, trade-offs, and rationale for
the Vertex AI GitOps Platform. Each section maps to a real interview question
you will face at the target companies.

---

## ADR-001: Why ArgoCD over Flux?

**Decision**: ArgoCD

**Rationale**:
- UI-first debugging — in an interview demo, visual reconciliation diff is
  immediately comprehensible to hiring managers
- App-of-Apps pattern maps cleanly to multi-team / multi-environment setups
  common in Lloyds / Barclays (separate Helm charts per squad)
- Sync waves allow ordered dependency bootstrapping (Vault before apps,
  Gatekeeper before workloads)
- Better Harness integration (ArgoCD application health checks usable as
  Harness deployment verification)

**Trade-off**: Flux is lighter and more GitOps-pure (no UI server), better for
  fully automated pipelines. ArgoCD's pull interval (3 min) vs Flux's
  event-driven sync is acceptable for this platform's change velocity.

---

## ADR-002: Why Harness CD over pure ArgoCD rollouts?

**Decision**: Harness for CD orchestration, ArgoCD for GitOps state sync

**Rationale**:
- These two tools are complementary, not competing. ArgoCD ensures the cluster
  *matches* Git. Harness orchestrates *when and how* to change Git (and thus
  the cluster).
- Harness provides the approval gate UI, Slack notifications, and canary
  verification steps that ArgoCD does not have natively.
- Harness Free tier supports one pipeline per account — sufficient for demo.
- The Delegate pattern (agent inside cluster) is architecturally identical to
  what Goldman Sachs uses internally (agent-based CD with no inbound firewall
  holes).

**Trade-off**: Additional SaaS dependency. Mitigated by the fact that the
  Harness Delegate is inside the cluster and Harness SaaS only coordinates.
  If Harness is unavailable, ArgoCD auto-sync still maintains desired state.

---

## ADR-003: Vault Dev Mode vs Production Mode

**Decision**: Dev mode for local demo; Terraform module targets production HA

**Rationale**:
- Dev mode requires zero disk persistence, starts in seconds, no unsealing.
  Critical for a `./scripts/04-install-vault.sh` that completes in < 60s.
- K8s auth backend is identical in dev and production — the interview-relevant
  part (pod identity → Vault token) works the same.
- The `terraform/modules/vault/` module shows production thinking: HA Raft
  storage, auto-unseal via AWS KMS / GCP CKMS.

**Trade-off**: Dev mode loses secrets on pod restart. Documented clearly;
  scripts re-initialise if Vault pod restarts (idempotency handled by
  checking if auth backend already exists).

---

## ADR-004: Why Istio over Linkerd or Cilium?

**Decision**: Istio 1.21 (ambient mesh optional, sidecar mode default)

**Rationale**:
- Istio is the de-facto standard at the target companies. Goldman Sachs runs
  Istio internally. Lloyds and Barclays both reference Istio in their JDs.
- Kiali is Istio-native — provides the service topology view critical for
  demonstrating distributed tracing understanding.
- PeerAuthentication STRICT mode is a one-line Kubernetes manifest that
  enforces mTLS cluster-wide. This maps directly to FSS/PRA requirements for
  in-transit encryption.
- Istio's VirtualService enables the canary traffic split used by Harness
  verification, without needing a separate ingress controller.

**Trade-off**: Istio is resource-hungry. On 16 GB M1, allocate at least
  512Mi per Envoy sidecar. This is managed in scripts/03-install-istio.sh
  with a minimal profile and resource tuning.

---

## ADR-005: OPA Gatekeeper vs Kyverno for Policy Enforcement

**Decision**: OPA Gatekeeper with Rego policies

**Rationale**:
- Rego is the language of OPA, which is the CNCF standard for policy as code.
  Goldman Sachs and NVIDIA both use OPA internally.
- Rego policies can be unit-tested with `opa test` — policies treated as code
  with their own test suite. This is the interview-differentiating point.
- ConstraintTemplates allow reusable policy patterns: write once, parameterise
  per use case.
- Model governance (SR 11-7) maps directly to a `RequireModelCard` constraint.

**Trade-off**: Rego has a steeper learning curve than Kyverno's YAML-native
  policies. Kyverno would be simpler to demonstrate quickly. However, Rego
  proficiency is specifically asked about in Goldman / NVIDIA platform roles.

---

## ADR-006: ML Framework Choice (scikit-learn vs PyTorch/TensorFlow)

**Decision**: scikit-learn for the demo model; architecture supports any framework

**Rationale**:
- scikit-learn models are tiny (< 1MB serialised .joblib), load in milliseconds,
  and run without GPU on M1 ARM. The demo works reliably offline.
- The *serving infrastructure* (FastAPI, Envoy, Prometheus metrics, drift
  detection) is framework-agnostic. Interviewers care about the platform, not
  the model.
- Evidently AI has first-class support for scikit-learn data schemas.
- Extending to PyTorch/TensorFlow is a single Dockerfile change.

**NVIDIA Extension**: For NVIDIA roles, add to `helm/ml-model/values.yaml`:
  ```yaml
  resources:
    limits:
      nvidia.com/gpu: 1
  tolerations:
    - key: nvidia.com/gpu
      operator: Exists
      effect: NoSchedule
  ```

---

## ADR-007: MCP Server vs Custom Webhook for AI Agent

**Decision**: MCP (Model Context Protocol) server

**Rationale**:
- MCP is Anthropic's open standard for AI tool use, now widely adopted.
  Building an MCP server demonstrates awareness of the latest AI integration
  patterns — directly relevant to NVIDIA's AI Enterprise and Goldman's
  AI/Strats teams.
- MCP tools are composable — the same server works with Claude Desktop,
  custom agents, and any MCP-compatible client.
- The tool definitions (`query_prometheus`, `rollback_deployment`, etc.) are
  clean function signatures that map 1:1 to Kubernetes operations, making the
  agent provably safe and auditable.

**Trade-off**: MCP is newer than Langchain/custom webhook approaches. Mitigated
  by the fact that all target companies are evaluating MCP for internal tooling.

---

## ADR-008: Jenkins vs GitHub Actions vs Tekton for CI

**Decision**: Jenkins (Helm on Kubernetes)

**Rationale**:
- Jenkins is explicitly listed in job descriptions at Lloyds and Barclays.
  These banks still run large Jenkins estates.
- Running Jenkins on Kubernetes (via the official Helm chart) is modern —
  ephemeral agent pods, no static build nodes, elastic scaling.
- The Jenkinsfile demonstrates shared library patterns and structured stages
  that experienced Jenkins users will recognise immediately.
- GitHub Actions would be simpler but misses the on-premises / air-gapped
  requirement common in FS (Financial Services).

**Trade-off**: Jenkins has a heavier footprint. Allocated 2Gi RAM in
  scripts/05-install-jenkins.sh with persistent volume for the Jenkins home.

---

## ADR-009: Terraform Scope (Local vs Cloud)

**Decision**: Terraform modules ready for AWS/GCP; local env is a no-op reference

**Rationale**:
- The local Kubernetes cluster needs no Terraform (everything is Helm/kubectl).
- Writing Terraform modules for the same resources (EKS, RDS, MSK, GKE)
  demonstrates IaC maturity expected at all four target companies.
- The module structure (`modules/vault`, `modules/networking`, `modules/monitoring`)
  is reusable across environments — the `environments/aws` and `environments/gcp`
  directories just wire modules together with environment-specific variables.
- This is the "show your cloud thinking without requiring a cloud account" pattern.

---

## Resource Allocation Guide (16 GB M1)

| Component | CPU Request | RAM Request | Notes |
|-----------|-------------|-------------|-------|
| Istio Pilot | 100m | 512Mi | Minimal profile |
| Istio per-sidecar | 10m | 40Mi | × number of pods |
| Vault | 100m | 256Mi | Dev mode |
| Jenkins controller | 500m | 1Gi | JVM tuned |
| ArgoCD | 100m | 256Mi | |
| Prometheus | 200m | 512Mi | 15d retention |
| Grafana | 100m | 128Mi | |
| Jaeger | 100m | 256Mi | In-memory storage |
| Kiali | 50m | 128Mi | |
| OPA Gatekeeper | 100m | 256Mi | |
| sample-app (×2) | 50m | 64Mi | |
| ml-model (×2) | 100m | 256Mi | |
| **Total** | **~1.7 CPU** | **~4.5 Gi** | Well within 16 GB |

Docker Desktop recommended settings: 8 CPUs, 10 GB RAM, 2 GB swap.

---

## Sequence Diagram: Full Deploy Flow

```
Developer          Jenkins          Harness         ArgoCD          Kubernetes
    │                  │                │               │                │
    │──git push──────► │                │               │                │
    │                  │─SAST(Bandit)──►│               │                │
    │                  │─Snyk SCA──────►│               │                │
    │                  │─Trivy scan────►│               │                │
    │                  │─Model Card────►│               │                │
    │                  │─docker build──►│               │                │
    │                  │─docker push───►│               │                │
    │                  │─update values.yaml             │                │
    │                  │─git commit/push────────────────►               │
    │                  │─notify Harness─►               │                │
    │                  │                │─deploy 10%────────────────────►│
    │                  │                │─wait metrics──────────────────►│
    │◄─Slack alert─────│────────────────│               │                │
    │──approve─────────│───────────────►│               │                │
    │                  │                │─promote 100%──────────────────►│
    │                  │                │               │◄─sync──────────│
    │                  │                │               │─reconcile──────►│
```

---

## Interview Talking Points (Quick Reference)

See `docs/interview-talking-points.md` for the full structured prep.

**Core narrative**: "I built a platform that treats AI model deployment with the
same rigour as a financial transaction — every model has a card, every deploy
is gated, every secret is dynamic, and every anomaly triggers an autonomous
response agent."
