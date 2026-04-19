#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}  $*"; }
info() { echo -e "${YELLOW}[--]${NC}  $*"; }

echo "=========================================="
echo " Script 05 — Install Jenkins (Helm/k8s)"
echo "=========================================="

if kubectl get deployment jenkins -n jenkins &>/dev/null; then
  ok "Jenkins already installed"
else
  info "Installing Jenkins via Helm..."
  helm upgrade --install jenkins jenkins/jenkins \
    -n jenkins --create-namespace \
    --set controller.admin.password=admin123 \
    --set controller.resources.requests.cpu=250m \
    --set controller.resources.requests.memory=512Mi \
    --set controller.resources.limits.cpu=1000m \
    --set controller.resources.limits.memory=1Gi \
    --set controller.javaOpts="-Xms256m -Xmx512m" \
    --set controller.serviceType=ClusterIP \
    --set controller.installPlugins[0]=kubernetes:latest \
    --set controller.installPlugins[1]=workflow-aggregator:latest \
    --set controller.installPlugins[2]=git:latest \
    --set controller.installPlugins[3]=blueocean:latest \
    --set controller.installPlugins[4]=docker-workflow:latest \
    --set controller.installPlugins[5]=snyk-security-scanner:latest \
    --set agent.resources.requests.cpu=100m \
    --set agent.resources.requests.memory=256Mi \
    --set persistence.enabled=true \
    --set persistence.size=5Gi \
    --wait --timeout 8m
  ok "Jenkins installed"
fi

info "Waiting for Jenkins to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=jenkins-controller -n jenkins --timeout=300s
ok "Jenkins ready"

echo ""
echo "  Access:   kubectl port-forward -n jenkins svc/jenkins 8888:8080"
echo "  URL:      http://localhost:8888"
echo "  User:     admin"
echo "  Pass:     admin123"
echo ""
echo -e "${GREEN}Script 05 complete.${NC}"
