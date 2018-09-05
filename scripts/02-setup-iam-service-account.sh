#!/usr/bin/env bash
set -e

if [ -z "${AWS_ACCOUNT_NAME}" ]; then
  echo "Missing AWS_ACCOUNT_NAME variable!"
  exit 1
fi

S3_BUCKET="${AWS_ACCOUNT_NAME}-vault-storage"
SERICE_ACCOUNT="vault-server@{AWS_ACCOUNT_NAME}.iam"

cat > iam_policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::${S3_BUCKET}"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::${S3_BUCKET}/*"]
    }
  ]
}
EOF
aws iam put-role-policy --role-name nodes.ss.rdti.us --policy-name vault-policy --policy-document file://iam_policy.json
rm iam_policy.json
