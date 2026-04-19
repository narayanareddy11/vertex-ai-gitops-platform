#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}  $*"; }
info() { echo -e "${YELLOW}[--]${NC}  $*"; }

install_brew() {
  local pkg=$1; local tap=${2:-}
  if command -v "$pkg" &>/dev/null; then
    ok "$pkg already installed"
  else
    info "Installing $pkg..."
    [ -n "$tap" ] && brew tap "$tap"
    brew install "$pkg"
    ok "$pkg installed"
  fi
}

echo "=========================================="
echo " Script 01 — Install CLI Tools"
echo "=========================================="

# Helm
install_brew helm

# ArgoCD CLI
install_brew argocd argoproj/tap

# Istio
install_brew istioctl

# Vault
install_brew vault hashicorp/tap

# OPA
install_brew opa

# Terraform
install_brew terraform hashicorp/tap

# Snyk (SCA scanner)
if command -v snyk &>/dev/null; then
  ok "snyk already installed"
else
  info "Installing snyk via npm..."
  npm install -g snyk 2>/dev/null || brew install snyk
  ok "snyk installed"
fi

# Trivy (container scanner)
install_brew trivy aquasecurity/trivy

# Add Helm repos
info "Adding Helm repos..."
helm repo add stable          https://charts.helm.sh/stable                          2>/dev/null || true
helm repo add jenkins         https://charts.jenkins.io                               2>/dev/null || true
helm repo add argo            https://argoproj.github.io/argo-helm                   2>/dev/null || true
helm repo add hashicorp       https://helm.releases.hashicorp.com                    2>/dev/null || true
helm repo add istio           https://istio-release.storage.googleapis.com/charts    2>/dev/null || true
helm repo add open-policy-agent https://open-policy-agent.github.io/gatekeeper/charts 2>/dev/null || true
helm repo add prometheus      https://prometheus-community.github.io/helm-charts     2>/dev/null || true
helm repo add grafana         https://grafana.github.io/helm-charts                  2>/dev/null || true
helm repo add jaeger          https://jaegertracing.github.io/helm-charts            2>/dev/null || true
helm repo add kiali           https://kiali.org/helm-charts                          2>/dev/null || true
helm repo update
ok "Helm repos updated"

echo ""
echo -e "${GREEN}Script 01 complete.${NC}"
