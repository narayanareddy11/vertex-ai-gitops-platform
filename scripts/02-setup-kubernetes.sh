#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}  $*"; }
info() { echo -e "${YELLOW}[--]${NC}  $*"; }

apply_if_absent() {
  local kind=$1 name=$2 ns=${3:-}
  local ns_flag=""
  [ -n "$ns" ] && ns_flag="-n $ns"
  if kubectl get "$kind" "$name" $ns_flag &>/dev/null; then
    ok "$kind/$name already exists"
  else
    kubectl apply -f - <<EOF
$4
EOF
    ok "$kind/$name created"
  fi
}

echo "=========================================="
echo " Script 02 — Kubernetes Namespaces & RBAC"
echo "=========================================="

# Namespaces
for ns in apps ml-platform vault jenkins argocd monitoring istio-system gatekeeper-system; do
  if kubectl get namespace "$ns" &>/dev/null; then
    ok "namespace/$ns already exists"
  else
    kubectl create namespace "$ns"
    ok "namespace/$ns created"
  fi
done

# Istio injection label
for ns in apps ml-platform; do
  kubectl label namespace "$ns" istio-injection=enabled --overwrite
  ok "istio-injection enabled on $ns"
done

# Default-deny NetworkPolicy for apps and ml-platform
for ns in apps ml-platform; do
  if kubectl get networkpolicy default-deny -n "$ns" &>/dev/null; then
    ok "NetworkPolicy/default-deny already exists in $ns"
  else
    kubectl apply -n "$ns" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: $ns
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
  egress:
  - ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
EOF
    ok "NetworkPolicy/default-deny created in $ns"
  fi
done

# Allow intra-namespace + monitoring scrape for apps
for ns in apps ml-platform; do
  kubectl apply -n "$ns" -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-intra-namespace
  namespace: $ns
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: $ns
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: monitoring
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: istio-system
  egress:
  - {}
EOF
  ok "NetworkPolicy/allow-intra-namespace applied to $ns"
done

# Label monitoring namespace for scraping
kubectl label namespace monitoring kubernetes.io/metadata.name=monitoring --overwrite 2>/dev/null || true

echo ""
echo -e "${GREEN}Script 02 complete — namespaces and network policies configured.${NC}"
