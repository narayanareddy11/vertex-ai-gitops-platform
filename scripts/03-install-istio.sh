#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}  $*"; }
info() { echo -e "${YELLOW}[--]${NC}  $*"; }

echo "=========================================="
echo " Script 03 — Install Istio (strict mTLS)"
echo "=========================================="

# Check if already installed
if kubectl get deployment istiod -n istio-system &>/dev/null; then
  ok "Istio already installed — skipping Helm install"
else
  info "Installing Istio base..."
  helm upgrade --install istio-base istio/base \
    -n istio-system --create-namespace \
    --set defaultRevision=default \
    --wait --timeout 5m

  info "Installing Istiod (control plane)..."
  helm upgrade --install istiod istio/istiod \
    -n istio-system \
    --set pilot.resources.requests.cpu=100m \
    --set pilot.resources.requests.memory=512Mi \
    --set pilot.resources.limits.cpu=500m \
    --set pilot.resources.limits.memory=1Gi \
    --set global.proxy.resources.requests.cpu=10m \
    --set global.proxy.resources.requests.memory=40Mi \
    --set global.proxy.resources.limits.cpu=200m \
    --set global.proxy.resources.limits.memory=128Mi \
    --wait --timeout 5m

  ok "Istiod installed"
fi

# Install ingress gateway
if kubectl get deployment istio-ingressgateway -n istio-system &>/dev/null; then
  ok "Istio ingress gateway already installed"
else
  info "Installing Istio ingress gateway..."
  helm upgrade --install istio-ingress istio/gateway \
    -n istio-system \
    --set service.type=NodePort \
    --wait --timeout 5m
  ok "Ingress gateway installed"
fi

# Enforce strict mTLS cluster-wide
info "Applying strict PeerAuthentication..."
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
EOF
ok "Strict mTLS enforced cluster-wide"

# Verify
kubectl get pods -n istio-system
echo ""
echo -e "${GREEN}Script 03 complete — Istio running with strict mTLS.${NC}"
