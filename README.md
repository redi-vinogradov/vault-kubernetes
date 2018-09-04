# Running Hashicorp Vault on AWS Kubernetes
## 00 Setup storage
Vault requires a storage backend in order to persist data. This deployment 
leverages [AWS S3][s3]. We need to create the storage bucket first.

```text
bash scripts/00-setup-storage.sh
```

AWS S3 bucket names must be globally unique across all S3. To ensure 
uniquiness, the bucket will be named "${AWS_ACCOUNT_NAME}-vault-storage".

For security purposes, it is not recommended that other applications or services
have access to this bucket. Even though the data is encrypted at rest, it's best
to limit the scope of access as much as possible.

## 01 Setup AWS KMS
The [vault-init][vault-init] container automatically initializes and unseals the
Vault cluster. It stores the initial root token and unseal keys in the same
storage bucket, but encrypts them using a KMS key. We must create this KMS key
in advance.

```text
bash ./scripts/01-setup-kms.sh
```

## 02 Create IAM Service Account
If you are the first user in your project (as is the case with the dedicated
projects for this workshop), you are a super user with full permission. It is a
best practice to create a limited, dedicated service account that has only the
required permissions. The `02-create-iam-service-account.sh` script creates a
dedicated service account in the project and grants that service account the
most minimal set of permissions, in particular:

- The ability to read/write to the AWS S3 bucket created above
- The ability to encrypt/decrypt data with the KMS key created above
- The ability to generate new service accounts (not required to use Vault, but
  helpful if you plan to use the Vault AWS secrets engine)

```text
bash ./scripts/02-setup-iam-service-account.sh
```

## 03 Create certificates

We used 'ss.rdti.us' here and looking for AWS ALB 'k8s-ingress-ss'

## 04 Setup config

We use 'load_balancer_dns_name' instead of 'load_balancer_address' and
's3_bucket_name' instead of 'gcs_bucket_name' (update vault-init).

## 05 Deploy Vault service and ingress
In this example we create vault ingress rules for external access and internal
service called 'vault'.

```text
bash .scripts/05-deploy-ingress.sh
```

## 06 Setup Comms

