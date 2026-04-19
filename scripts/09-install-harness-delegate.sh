#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}  $*"; }
info() { echo -e "${YELLOW}[--]${NC}  $*"; }
note() { echo -e "${CYAN}[NOTE]${NC} $*"; }

echo "=========================================="
echo " Script 09 — Install Harness Delegate"
echo "=========================================="

note "Harness Delegate requires a free account at app.harness.io"
note "If you haven't signed up yet, do so now and come back."
echo ""

# Check if delegate token is set
if [ -z "${HARNESS_DELEGATE_TOKEN:-}" ]; then
  echo "  To get your delegate token:"
  echo "  1. Login at https://app.harness.io"
  echo "  2. Go to Account Settings → Account Resources → Delegates"
  echo "  3. Click 'New Delegate' → Kubernetes → copy the YAML"
  echo "  4. Extract the token value from the Secret in the YAML"
  echo "  5. Re-run: HARNESS_DELEGATE_TOKEN=<token> HARNESS_ACCOUNT_ID=<id> ./09-install-harness-delegate.sh"
  echo ""
  note "Skipping Harness Delegate install (token not set). All other services are running."
  exit 0
fi

HARNESS_ACCOUNT_ID="${HARNESS_ACCOUNT_ID:?Set HARNESS_ACCOUNT_ID}"
DELEGATE_NAME="${DELEGATE_NAME:-vertex-gitops-delegate}"
NAMESPACE="harness-delegate"

kubectl create namespace "$NAMESPACE" 2>/dev/null || ok "namespace/$NAMESPACE already exists"

if kubectl get deployment "$DELEGATE_NAME" -n "$NAMESPACE" &>/dev/null; then
  ok "Harness Delegate already deployed"
  exit 0
fi

info "Deploying Harness Delegate to namespace: $NAMESPACE"
kubectl apply -n "$NAMESPACE" -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${DELEGATE_NAME}-token
  namespace: ${NAMESPACE}
type: Opaque
stringData:
  DELEGATE_TOKEN: "${HARNESS_DELEGATE_TOKEN}"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${DELEGATE_NAME}
  namespace: ${NAMESPACE}
spec:
  replicas: 1
  selector:
    matchLabels:
      harness.io/name: ${DELEGATE_NAME}
  template:
    metadata:
      labels:
        harness.io/name: ${DELEGATE_NAME}
    spec:
      serviceAccountName: default
      containers:
      - name: delegate
        image: harness/delegate:latest
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: 500m
            memory: 512Mi
        env:
        - name: ACCOUNT_ID
          value: "${HARNESS_ACCOUNT_ID}"
        - name: DELEGATE_TOKEN
          valueFrom:
            secretKeyRef:
              name: ${DELEGATE_NAME}-token
              key: DELEGATE_TOKEN
        - name: MANAGER_HOST_AND_PORT
          value: "https://app.harness.io"
        - name: DEPLOY_MODE
          value: KUBERNETES
        - name: DELEGATE_NAME
          value: "${DELEGATE_NAME}"
        - name: DELEGATE_TYPE
          value: KUBERNETES
        - name: DELEGATE_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
EOF

ok "Harness Delegate deployment applied"
info "Waiting for Delegate pod..."
kubectl wait --for=condition=ready pod -l harness.io/name="$DELEGATE_NAME" \
  -n "$NAMESPACE" --timeout=180s && ok "Delegate pod ready"

echo ""
echo "  Check status at: https://app.harness.io → Delegates"
echo ""
echo -e "${GREEN}Script 09 complete.${NC}"
