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
This exmaple presumes that your k8s cluster was created with KOPS and nodes are
already using IAM role. In this step we will create new IAM policy and attach it
to existing IAM role. The following permissions will be granted:

!! script has hardcoded ss.rdti.us

- The ability to read/write to the AWS S3 Vault bucket
- The ability to encrypt/decrypt data with the KMS key created above

```text
bash ./scripts/02-setup-iam-service-account.sh
```

## 03 Create Vault namespace
In this example we are using dedicated k8s namespace called 'vault' for storing
all Vault related objects.

```text
bash ./scripts/03-create-namespace.sh
```

## 04 Create certificates
We used 'ss.rdti.us' here and looking for AWS ALB 'k8s-ingress-ss'

!! script has hardcoded ss.rdti.us

```text
bash ./scripts/04-create-certs.sh
```

## 05 Setup config
We use 'load_balancer_dns_name' instead of 'load_balancer_address' and
's3_bucket_name' instead of 'gcs_bucket_name' (update vault-init).

```text
bash ./scripts/05-setup-config.sh
```

## 06 Deploy Vault
In this example we create vault ingress rules for external access and internal
service called 'vault'.

```text
bash .scripts/06-deploy-vault.sh
```

## 07 Vault initialization and configure

```bash
kubectl -n vault exec -ti vault-0 -- sh
export VAULT_SKIP_VERIFY="true"
```

### 07.1 Vault initialization
! Please be advised that unseal keys and root token from this command output
should be stored in a safe place for future use. Loosing these keys can led to
impossibility of unsealing the Vault.

```bash
vault operator init
```

### 07.2 Unsealing Vault
In order to unsel the Vault we need to use 3 unseal keys from previous output.

```bash
vault operator unseal <Unseal Key 1>
vault operator unseal <Unseal Key 2>
vault operator unseal <Unseal Key 3>
```

Check if Vault is unsealed successfully:

```bash
vault status
Key             Value
---             -----
Seal Type       shamir
Sealed          false
Total Shares    5
Threshold       3
Version         0.10.4
...
```

### 07.3 Login to Vault and configure kubernetes auth
In this step you need to use the root key from initialization output and
vault-tokenreview service token.

#### 07.3.1 Get vault-tokenreview service token
This step should be executed on worker node.

```bash
SECRET_NAME=$(kubectl -n default get serviceaccount vault-tokenreview \
-o jsonpath='{.secrets[0].name}')

TR_ACCOUNT_TOKEN=$(kubectl -n default get secret ${SECRET_NAME} \
-o jsonpath='{.data.token}' | base64 --decode)

echo ${TR_ACCOUNT_TOKEN}
```

#### 07.3.2 Enable and configure kubernetes auth
This step should be executed in vault pod. Please use $TR_ACCOUNT_TOKEN from
previous command as your 'token_reviewer_jwt'.

```bash
vault login <Root Key>
vault auth enable kubernetes
vault write auth/kubernetes/config \
  kubernetes_host="https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_SERVICE_PORT_HTTPS}" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  token_reviewer_jwt="eyJhbGciOiJSUzI1NiI..."
```

#### 07.3.3 Create test policy and secret
First we are going to create a policy that allows read/write/delete from
anything under "myapp" in the kv secrets engine. Next we will create a static
credential at `secret/myapp/config` with a username and password.

```bash
vault policy write demo-policy - <<EOH
path "secret/demo/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOH

vault kv put secret/myapp/config \
  ttl="60m" \
  username="appuser" \
  password="apppassword"
```

#### 07.3.4 Create app role
In this step we are mapping an application or service in Kunbernetes to a series
of policies in Vault. That way, when an application successfully authenticates
to Vault via its JWT token, Vault knows which policies to assgin to the
response.

```bash
vault write auth/kubernetes/role/myapp-role \
  bound_service_account_names=vault-tokenreview \
  bound_service_account_namespaces=default \
  policies=demo-policy \
  ttl=60m
```

## 08 Run your app with Vault secrets
In this example we will run simple curl test to get our secure credentials from
Vault using Kubernetes service account we use for our pod.

```bash
kubectl run tmp --rm -ti --serviceaccount=vault-tokenreview --image alpine
```

In the container run

```bash
apk add curl jq

KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

VAULT_K8S_LOGIN=$(curl -k -X POST --data \
  '{"jwt": "'"$KUBE_TOKEN"'", "role": "myapp-role"}' \
  https://vault.vault.svc.cluster.local:443/v1/auth/kubernetes/login)

X_VAULT_TOKEN=$(echo $VAULT_K8S_LOGIN | jq -r '.auth.client_token')
```

And finally

```bash
MYCREDS=$(curl -k --header "X-Vault-Token: $X_VAULT_TOKEN" \
  https://vault.vault.svc.cluster.local:443/v1/secret/myapp/config)

echo $MYCREDS | jq
```
