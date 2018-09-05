#!/usr/bin/env bash
set -e

kubectl apply -f k8s/vault-statefulset.yaml
kubectl apply -f k8s/vault-service.yaml
kubectl apply -f k8s/vault-ingress.yaml
