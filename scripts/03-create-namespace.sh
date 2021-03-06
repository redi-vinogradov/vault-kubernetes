#!/usr/bin/env bash
set -e

kubectl apply -f - <<EOH
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-tokenreview
EOH
kubectl apply -f - <<EOH
---
apiVersion: v1
kind: Namespace
metadata:
  name: vault
EOH
kubectl apply -f - <<EOH
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: vault-tokenreview
  namespace: vault
EOH
