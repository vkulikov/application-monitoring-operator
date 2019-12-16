#!/bin/bash

PROMETHEUS_OPERATOR_VERSION="$1"
GRAFANA_OPERATOR_VERSION="$2"

# create the project and add a label
oc new-project application-monitoring
oc label namespace application-monitoring monitoring-key=middleware

# Application Monitoring Operator
# AMO CRD
oc apply -f ./deploy/crds/ApplicationMonitoring.yaml

# AMO Cluster Roles & RoleBindings
oc apply -f ./deploy/roles
oc apply -f ./deploy/operator_roles/service_account.yaml
oc apply -f ./deploy/operator_roles/role.yaml
oc apply -f ./deploy/operator_roles/role_binding.yaml

# BlackboxTarget
oc apply -f ./deploy/crds/BlackboxTarget.yaml

# Grafana CRDs
oc apply -f https://raw.githubusercontent.com/integr8ly/grafana-operator/$GRAFANA_OPERATOR_VERSION/deploy/crds/Grafana.yaml
oc apply -f https://raw.githubusercontent.com/integr8ly/grafana-operator/$GRAFANA_OPERATOR_VERSION/deploy/crds/GrafanaDashboard.yaml
oc apply -f https://raw.githubusercontent.com/integr8ly/grafana-operator/$GRAFANA_OPERATOR_VERSION/deploy/crds/GrafanaDataSource.yaml

# Prometheus CRDs
oc apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/$PROMETHEUS_OPERATOR_VERSION/example/prometheus-operator-crd/podmonitor.crd.yaml
oc apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/$PROMETHEUS_OPERATOR_VERSION/example/prometheus-operator-crd/prometheus.crd.yaml
oc apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/$PROMETHEUS_OPERATOR_VERSION/example/prometheus-operator-crd/alertmanager.crd.yaml
oc apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/$PROMETHEUS_OPERATOR_VERSION/example/prometheus-operator-crd/prometheusrule.crd.yaml
oc apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/$PROMETHEUS_OPERATOR_VERSION/example/prometheus-operator-crd/servicemonitor.crd.yaml



# AMO Deployment
until oc auth can-i create prometheus -n application-monitoring --as system:serviceaccount:application-monitoring:application-monitoring-operator; do
    echo "Waiting for all CRDs and SA permissions to be applied before deploying operator..." && sleep 1
done

oc apply -f ./deploy/operator.yaml
oc apply -f ./deploy/examples/ApplicationMonitoring.yaml
