#!/usr/bin/env bash
set -e

kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Service
metadata:
  name: vault
  namespace: vault
  labels:
    app: vault
spec:
  type: ClusterIP
  selector:
    app: vault
  ports:
  - name: vault-port
    port: 443
    targetPort: 8200
    protocol: TCP
EOF

kubectl apply -f - <<EOF
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: vault
  namespace: vault
  labels:
    app: vault
spec:
  rules:
  - host: vault.ss.rdti.us
    http:
      paths:
      - backend:
          serviceName: vault
          servicePort: 443
        path: /
EOF
