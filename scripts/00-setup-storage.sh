#!/usr/bin/env bash
set -e

if [ -z "${AWS_ACCOUNT_NAME}" ]; then
  echo "Missing AWS_ACCOUNT_NAME variable!"
  exit 1
fi

aws s3 mb "s3://${AWS_ACCOUNT_NAME}-vault-storage"
