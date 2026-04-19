#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}  $*"; }
info() { echo -e "${YELLOW}[--]${NC}  $*"; }

echo "=========================================="
echo " Script 07 — Install OPA Gatekeeper"
echo "=========================================="

if kubectl get deployment gatekeeper-controller-manager -n gatekeeper-system &>/dev/null; then
  ok "OPA Gatekeeper already installed"
else
  info "Installing OPA Gatekeeper..."
  helm upgrade --install gatekeeper open-policy-agent/gatekeeper \
    -n gatekeeper-system --create-namespace \
    --set controllerManager.resources.requests.cpu=100m \
    --set controllerManager.resources.requests.memory=256Mi \
    --set audit.resources.requests.cpu=100m \
    --set audit.resources.requests.memory=256Mi \
    --wait --timeout 5m
  ok "OPA Gatekeeper installed"
fi

info "Waiting for Gatekeeper webhooks..."
kubectl wait --for=condition=ready pod -l control-plane=controller-manager -n gatekeeper-system --timeout=120s
sleep 5   # let webhook register

# Apply ConstraintTemplates
info "Applying ConstraintTemplate: RequireModelCard..."
kubectl apply -f - <<'EOF'
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: requiremodelcard
spec:
  crd:
    spec:
      names:
        kind: RequireModelCard
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package requiremodelcard
        violation[{"msg": msg}] {
          input.review.kind.kind == "Pod"
          not input.review.object.metadata.annotations["ai.platform/model-card"]
          namespace := input.review.object.metadata.namespace
          namespace == "ml-platform"
          msg := sprintf("Pod '%v' in namespace 'ml-platform' must have annotation ai.platform/model-card", [input.review.object.metadata.name])
        }
EOF
ok "RequireModelCard template applied"

info "Applying ConstraintTemplate: RequireResourceLimits..."
kubectl apply -f - <<'EOF'
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: requireresourcelimits
spec:
  crd:
    spec:
      names:
        kind: RequireResourceLimits
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package requireresourcelimits
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.resources.limits.cpu
          msg := sprintf("Container '%v' must set resources.limits.cpu", [container.name])
        }
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not container.resources.limits.memory
          msg := sprintf("Container '%v' must set resources.limits.memory", [container.name])
        }
EOF
ok "RequireResourceLimits template applied"

info "Applying ConstraintTemplate: DenyPrivilegedContainers..."
kubectl apply -f - <<'EOF'
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: denyprivilegedcontainers
spec:
  crd:
    spec:
      names:
        kind: DenyPrivilegedContainers
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package denyprivilegedcontainers
        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          container.securityContext.privileged == true
          msg := sprintf("Container '%v' must not run as privileged", [container.name])
        }
EOF
ok "DenyPrivilegedContainers template applied"

# Apply Constraints (enforce on apps + ml-platform)
info "Applying Constraints..."
kubectl apply -f - <<'EOF'
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: RequireModelCard
metadata:
  name: require-model-card-ml-platform
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    namespaces: ["ml-platform"]
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: DenyPrivilegedContainers
metadata:
  name: deny-privileged-all
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    namespaces: ["apps", "ml-platform"]
EOF
ok "Constraints applied"

echo ""
echo -e "${GREEN}Script 07 complete — OPA Gatekeeper enforcing model governance.${NC}"
