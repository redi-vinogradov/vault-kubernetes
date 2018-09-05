#!/usr/bin/env bash
set -e

kubectl create serviceaccount vault-auth
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
  namespace: vault
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: vault-auth
  namespace: vault
EOH
