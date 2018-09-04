#!/usr/bin/env bash
set -e

if [ -z "${AWS_ACCOUNT_NAME}" ]; then
  echo "Missing AWS_ACCOUNT_NAME variable!"
  exit 1
fi

LB_DNS_NAME="$(aws elbv2 describe-load-balancers --names k8s-ingress-ss --query 'LoadBalancers[*].DNSName' --output text)"
S3_BUCKET="${AWS_ACCOUNT_NAME}-vault-storage"

export VAULT_CACERT="$(pwd)/tls/ca.crt"
export VAULT_ADDR="https://${LB_DNS_NAME}:443"
export VAULT_TOKEN="$(aws s3 cp --quiet "s3://${S3_BUCKET}/root-token.enc" ; \
  aws kms decrypt \
    --ciphertext-blob fileb://root-token.enc \
    --query Plaintext \
    --output text | \
  base64 --decode)"
