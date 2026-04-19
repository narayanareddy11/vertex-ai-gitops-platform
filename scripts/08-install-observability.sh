#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[OK]${NC}  $*"; }
info() { echo -e "${YELLOW}[--]${NC}  $*"; }

echo "=========================================="
echo " Script 08 — Install Observability Stack"
echo "  Prometheus + Grafana + Jaeger + Kiali"
echo "=========================================="

# --- Prometheus + Grafana (kube-prometheus-stack) ---
if kubectl get deployment prometheus-grafana -n monitoring &>/dev/null; then
  ok "kube-prometheus-stack already installed"
else
  info "Installing kube-prometheus-stack..."
  helm upgrade --install prometheus prometheus/kube-prometheus-stack \
    -n monitoring --create-namespace \
    --set prometheus.prometheusSpec.resources.requests.cpu=200m \
    --set prometheus.prometheusSpec.resources.requests.memory=400Mi \
    --set prometheus.prometheusSpec.resources.limits.cpu=500m \
    --set prometheus.prometheusSpec.resources.limits.memory=800Mi \
    --set prometheus.prometheusSpec.retention=7d \
    --set grafana.resources.requests.cpu=100m \
    --set grafana.resources.requests.memory=128Mi \
    --set grafana.adminPassword=admin \
    --set grafana.sidecar.dashboards.enabled=true \
    --set grafana.sidecar.dashboards.label=grafana_dashboard \
    --set alertmanager.enabled=false \
    --set kubeEtcd.enabled=false \
    --set kubeControllerManager.enabled=false \
    --set kubeScheduler.enabled=false \
    --wait --timeout 8m
  ok "kube-prometheus-stack installed"
fi

# --- Jaeger ---
if kubectl get deployment jaeger -n monitoring &>/dev/null; then
  ok "Jaeger already installed"
else
  info "Installing Jaeger (all-in-one)..."
  helm upgrade --install jaeger jaeger/jaeger \
    -n monitoring \
    --set allInOne.enabled=true \
    --set collector.enabled=false \
    --set query.enabled=false \
    --set agent.enabled=false \
    --set allInOne.resources.requests.cpu=100m \
    --set allInOne.resources.requests.memory=256Mi \
    --set allInOne.resources.limits.cpu=300m \
    --set allInOne.resources.limits.memory=512Mi \
    --set storage.type=memory \
    --set provisionDataStore.cassandra=false \
    --set provisionDataStore.elasticsearch=false \
    --wait --timeout 5m
  ok "Jaeger installed"
fi

# --- Kiali ---
if kubectl get deployment kiali -n istio-system &>/dev/null; then
  ok "Kiali already installed"
else
  info "Installing Kiali..."
  helm upgrade --install kiali-server kiali/kiali-server \
    -n istio-system \
    --set auth.strategy=anonymous \
    --set external_services.prometheus.url="http://prometheus-kube-prometheus-prometheus.monitoring:9090" \
    --set external_services.tracing.enabled=true \
    --set external_services.tracing.in_cluster_url="http://jaeger-query.monitoring:16686/jaeger" \
    --set resources.requests.cpu=50m \
    --set resources.requests.memory=64Mi \
    --wait --timeout 5m
  ok "Kiali installed"
fi

# Istio telemetry for Prometheus scraping
kubectl apply -f - <<'EOF'
apiVersion: telemetry.istio.io/v1alpha1
kind: Telemetry
metadata:
  name: mesh-default
  namespace: istio-system
spec:
  metrics:
  - providers:
    - name: prometheus
EOF
ok "Istio telemetry configured"

echo ""
echo "  Grafana:    kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "              http://localhost:3000  (admin / admin)"
echo ""
echo "  Prometheus: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "              http://localhost:9090"
echo ""
echo "  Jaeger:     kubectl port-forward -n monitoring svc/jaeger-query 16686:16686"
echo "              http://localhost:16686"
echo ""
echo "  Kiali:      kubectl port-forward -n istio-system svc/kiali 20001:20001"
echo "              http://localhost:20001"
echo ""
echo -e "${GREEN}Script 08 complete.${NC}"
