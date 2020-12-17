# Vault Unsealer for Docker

Unseal a [vault](https://www.vaultproject.io) with a container given only environment variables via Kubernetes configmap.

This project was initially created to run as a kubernetes job to unseal a vault within the same cluster. This gives you the ability to pass env variables to a docker container and have it unseal a vault with the given keys. This image is based on the official vault image so many of the variables are the same. 

`VAULT_ADDR` - the location of the vault server, default pointed to Kubernetes service. You must specify the protocol (i.e. VAULT_ADDR=http://vault-sealed:8200)

`VAULT_UNSEAL_KEY_X` - this is the format of the unseal keys. In Kubernetes these are stored in a secret or configmap store and mounted to the Vault Unsealer container as environment variables.

This container will loop the unseal command to every workload behind the "vault-unsealed" service. Each time it loops it checks the vault status and then, if the vault is still sealed, it runs `unseal` with the next key, or if it is unsealed, it outputs that no unsealed vault container is available. 

## Instructions

1. Set vault key environment variables  as `VAULT_UNSEAL_KEY_1`, `VAULT_UNSEAL_KEY_2`, etc., up 15 keys are possible.
2. Set vault key address as `VAULT_ADDR`
3. Optionally set `VAULT_SKIP_VERIFY` to 1. 
4. Check the [vault docs](https://www.vaultproject.io/docs/commands/environment.html) on environment variables to see all of your options. 
5. Run the container and watch it unseal your vault.

## Example Kubernetes Config
### Configmap

```yaml
--- 
apiVersion: v1
kind: ConfigMap
metadata:
  name: vault-unseal
data:
  VAULT_ADDR: http://vault-sealed:8200
  VAULT_MAX_KEYS: "5"
  VAULT_SKIP_VERIFY: "1"
  VAULT_UNSEAL_KEY_1: <base64 encoded unseal key 1>
  VAULT_UNSEAL_KEY_2: <base64 encoded unseal key 1>
  VAULT_UNSEAL_KEY_3: <base64 encoded unseal key 1>
  VAULT_UNSEAL_KEY_4: <base64 encoded unseal key 1>
  VAULT_UNSEAL_KEY_5: <base64 encoded unseal key 1>
```
### Service
```yaml
---
apiVersion: v1
kind: Service
metadata:
  name: vault-sealed
spec:
  clusterIP: None
  ports:
    - name: vault
      port: 8200
      protocol: TCP
      targetPort: 8200
  publishNotReadyAddresses: true
  selector:
    app.kubernetes.io/instance: vault
    app.kubernetes.io/name: vault
    component: server
    vault-sealed: "true"
  sessionAffinity: None
  type: ClusterIP
```
### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations: {}
  labels: {}
  name: vault-unseal
spec:
  selector:
    matchLabels:
      app.kubernetes.io/instance: vault-unseal
      app.kubernetes.io/name: vault-unseal
  progressDeadlineSeconds: 600
  replicas: 1
  revisionHistoryLimit: 10
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app.kubernetes.io/instance: vault-unseal
        app.kubernetes.io/name: vault-unseal
    spec:
      containers:
        - envFrom:
            - configMapRef:
                name: vault-unseal
                optional: false
          image: <repo url>/vault-unseal:latest
          imagePullPolicy: Always
          name: vault-unseal
      dnsPolicy: ClusterFirst
      imagePullSecrets:
        - name: cx-harbor
      restartPolicy: Always
```