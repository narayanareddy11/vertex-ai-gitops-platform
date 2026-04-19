#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}  $*"; }
info() { echo -e "${YELLOW}[--]${NC}  $*"; }

echo "=========================================="
echo " Script 04 — Install HashiCorp Vault"
echo "=========================================="

# Install Vault via Helm (dev mode)
if kubectl get statefulset vault -n vault &>/dev/null; then
  ok "Vault already installed"
else
  info "Installing Vault (dev mode)..."
  helm upgrade --install vault hashicorp/vault \
    -n vault --create-namespace \
    --set server.dev.enabled=true \
    --set server.dev.devRootToken=root \
    --set server.resources.requests.cpu=100m \
    --set server.resources.requests.memory=256Mi \
    --set server.resources.limits.cpu=250m \
    --set server.resources.limits.memory=512Mi \
    --set injector.enabled=true \
    --set injector.resources.requests.cpu=50m \
    --set injector.resources.requests.memory=64Mi \
    --wait --timeout 5m
  ok "Vault installed"
fi

# Wait for Vault pod
info "Waiting for Vault pod to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n vault --timeout=120s
ok "Vault pod ready"

# Enable Kubernetes auth backend (idempotent)
info "Configuring Vault Kubernetes auth..."
kubectl exec -n vault vault-0 -- sh -c '
  export VAULT_TOKEN=root
  export VAULT_ADDR=http://127.0.0.1:8200

  # Enable k8s auth if not already enabled
  if vault auth list | grep -q kubernetes; then
    echo "K8s auth already enabled"
  else
    vault auth enable kubernetes
    vault write auth/kubernetes/config \
      kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"
    echo "K8s auth configured"
  fi

  # Create a policy for apps
  vault policy write app-policy - <<POLICY
path "secret/data/*" {
  capabilities = ["read"]
}
POLICY

  # Create roles for each app namespace
  for ns in apps ml-platform jenkins; do
    vault write auth/kubernetes/role/$ns-role \
      bound_service_account_names="*" \
      bound_service_account_namespaces="$ns" \
      policies=app-policy \
      ttl=1h 2>/dev/null || true
  done

  # Seed example secrets
  vault kv put secret/sample-app  db_password=demo_pass_123 api_key=demo_api_key_456
  vault kv put secret/ml-model    model_version=v1.0.0 registry=docker.io

  echo "Vault secrets seeded"
'
ok "Vault Kubernetes auth + secrets configured"

echo ""
echo "  Vault UI:   kubectl port-forward -n vault svc/vault 8200:8200"
echo "  Token:      root"
echo ""
echo -e "${GREEN}Script 04 complete.${NC}"
