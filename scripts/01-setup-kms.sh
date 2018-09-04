#!/usr/bin/env bash
set -e

KMS_CHECK=$(aws kms describe-key --key-id "alias/k8s/vault" --query 'KeyMetadata.KeyId' --output text)

if ! [ -x "$(which jq)" ]; then
  echo "Error: jq utility should be installed first"
  exit 1
fi

if ! [ "${KMS_CHECK}" ]; then
  KMS_KEY_ID=$(aws kms create-key --description "Hashicrop Vault Key used for storage seal/unseal" \
    --key-usage "ENCRYPT_DECRYPT" --origin "AWS_KMS" | jq -r .KeyMetadata.KeyId)

  aws kms create-alias --alias-name "alias/k8s/vault" --target-key-id "${KMS_KEY_ID}"

  if [ $? -eq 0 ]; then
    echo "AWS KMS key ID "${KMS_KEY_ID}" was crearted successfully"
  fi
else
  echo "Error: existing AWS KMS key with alias 'k8s/vault' found"
fi
