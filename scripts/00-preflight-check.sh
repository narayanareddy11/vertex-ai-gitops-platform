#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
fail() { echo -e "${RED}[FAIL]${NC} $*"; FAILED=$((FAILED+1)); }
FAILED=0

echo "=========================================="
echo " Vertex AI GitOps Platform - Preflight"
echo "=========================================="

# Kubernetes
if kubectl cluster-info &>/dev/null; then
  ok "Kubernetes reachable: $(kubectl config current-context)"
else
  fail "Kubernetes not reachable — enable it in Docker Desktop"
fi

# Node ready
READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c Ready || true)
[ "$READY" -ge 1 ] && ok "Nodes ready: $READY" || fail "No ready nodes"

# RAM check (Docker Desktop VM)
TOTAL_MEM=$(docker info 2>/dev/null | grep "Total Memory" | awk '{print $3}' | cut -d. -f1 || echo 0)
[ "${TOTAL_MEM:-0}" -ge 8 ] && ok "Docker Desktop RAM: ${TOTAL_MEM}GiB" || warn "Docker Desktop RAM ${TOTAL_MEM}GiB — recommend 10GiB"

# Required CLIs
for cmd in helm kubectl docker brew; do
  command -v "$cmd" &>/dev/null && ok "$cmd found: $(command -v $cmd)" || fail "$cmd not found"
done

# Optional CLIs (will be installed by script 01)
for cmd in argocd istioctl vault opa; do
  command -v "$cmd" &>/dev/null && ok "$cmd found" || warn "$cmd not installed yet (script 01 will install)"
done

# Helm repos
helm repo list &>/dev/null && ok "Helm repos configured" || warn "No Helm repos yet"

# Disk
FREE_GB=$(df -g / | awk 'NR==2{print $4}')
[ "${FREE_GB:-0}" -ge 20 ] && ok "Free disk: ${FREE_GB}GB" || warn "Free disk ${FREE_GB}GB — recommend 20GB+"

echo ""
if [ "$FAILED" -gt 0 ]; then
  echo -e "${RED}Preflight FAILED — $FAILED issue(s) above must be fixed before continuing.${NC}"
  exit 1
else
  echo -e "${GREEN}Preflight PASSED — ready to install.${NC}"
fi
