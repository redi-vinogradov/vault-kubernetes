#!/usr/bin/env bash
set -e

if [ -z "${AWS_ACCOUNT_NAME}" ]; then
  echo "Missing AWS_ACCOUNT_NAME variable!"
  exit 1
fi

LB_DNS_NAME="$(aws elbv2 describe-load-balancers --names k8s-ingress-ss --query 'LoadBalancers[*].DNSName' --output text)"
S3_BUCKET="${AWS_ACCOUNT_NAME}-vault-storage"
KMS_KEY="$(aws kms describe-key --key-id "alias/k8s/vault" --query 'KeyMetadata.KeyId' --output text)"

DIR="$(pwd)/tls"

kubectl create configmap vault \
  --from-literal "load_balancer_dns_name=${LB_DNS_NAME}" \
  --from-literal "s3_bucket_name=${S3_BUCKET}" \
  --from-literal "kms_key_id=${KMS_KEY}"

kubectl create secret generic vault-tls \
  --from-file "${DIR}/ca.crt" \
  --from-file "vault.crt=${DIR}/vault-combined.crt" \
  --from-file "vault.key=${DIR}/vault.key"
