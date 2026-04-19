#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}  $*"; }
info() { echo -e "${YELLOW}[--]${NC}  $*"; }

echo "=========================================="
echo " Script 06 — Install ArgoCD"
echo "=========================================="

if kubectl get deployment argocd-server -n argocd &>/dev/null; then
  ok "ArgoCD already installed"
else
  info "Installing ArgoCD..."
  helm upgrade --install argocd argo/argo-cd \
    -n argocd --create-namespace \
    --set server.resources.requests.cpu=100m \
    --set server.resources.requests.memory=128Mi \
    --set server.resources.limits.cpu=500m \
    --set server.resources.limits.memory=256Mi \
    --set repoServer.resources.requests.cpu=50m \
    --set repoServer.resources.requests.memory=64Mi \
    --set applicationSet.enabled=false \
    --set notifications.enabled=false \
    --set dex.enabled=false \
    --set server.insecure=true \
    --wait --timeout 8m
  ok "ArgoCD installed"
fi

info "Waiting for ArgoCD server..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=180s
ok "ArgoCD server ready"

# Get admin password
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "not-set")
ok "ArgoCD admin password retrieved"

# Login via CLI
info "Logging in to ArgoCD CLI..."
argocd login localhost:8080 \
  --username admin \
  --password "$ARGOCD_PASS" \
  --insecure \
  --port-forward \
  --port-forward-namespace argocd 2>/dev/null || true

# Register the local cluster
argocd cluster add docker-desktop \
  --port-forward \
  --port-forward-namespace argocd \
  --insecure \
  --yes 2>/dev/null || ok "Cluster already registered"

echo ""
echo "  Access:   kubectl port-forward -n argocd svc/argocd-server 8080:80"
echo "  URL:      http://localhost:8080"
echo "  User:     admin"
echo "  Pass:     $ARGOCD_PASS"
echo ""
echo -e "${GREEN}Script 06 complete.${NC}"
