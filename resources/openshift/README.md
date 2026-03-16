# OpenShift Deployment for Contact Management

This directory contains the Kustomize-based deployment configuration for the Contact Management microservice on OpenShift.

## Architecture

- **Kustomize**: Manages Kubernetes manifests with base and overlay structure
- **Environment Variables**: Secrets are created from environment variables (`.env` file)
- **OpenShift Native**: Uses Routes instead of Ingress, OCP storage classes

## Structure

```
openshift/
├── base/                           # Base Kustomize configuration
│   ├── kustomization.yaml          # Kustomize config
│   ├── namespace.yaml              # contact namespace
│   ├── serviceaccount.yaml         # Service account
│   ├── configmap.yaml              # Application properties
│   ├── postgres-pvc.yaml           # PostgreSQL persistent volume
│   ├── postgres-deployment.yaml    # PostgreSQL deployment
│   ├── postgres-service.yaml       # PostgreSQL service
│   ├── msr-deployment.yaml         # Microservice deployment
│   ├── msr-service.yaml            # Microservice service
│   ├── msr-route.yaml              # OpenShift route (TLS enabled)
│   ├── msr-hpa.yaml                # Horizontal Pod Autoscaler
│   └── msr-servicemonitor.yaml     # Prometheus ServiceMonitor
├── overlays/                       # Environment-specific overlays
│   └── production/                 # Production overlay (future use)
├── deploy.sh                       # Deployment script
├── .env.template                   # Environment variables template
└── README.md                       # This file
```

## Prerequisites

1. **OpenShift CLI (`oc`)** installed and configured
2. **Access to OpenShift cluster** with appropriate permissions
3. **Certificates**: Event Streams and EEM truststore files
4. **Container Registry Access**: Credentials for ghcr.io

## Deployment Steps

### 1. Configure Environment Variables

Copy the template and fill in your values:

```bash
cd resources/openshift
cp .env.template .env
```

Edit `.env` with your actual values:
- Container registry credentials
- Database credentials
- Event Streams configuration
- EEM configuration
- SAG Cloud registration details

**Important**: Make sure the truststore file paths in `.env` point to the actual certificate files.

### 2. Verify Cluster Access

```bash
oc whoami
oc cluster-info
```

### 3. Run Deployment

```bash
./deploy.sh
```

The script will:
1. Validate all required environment variables
2. Create the `contact` namespace
3. Create all required secrets from environment variables
4. Deploy all resources using Kustomize

### 4. Verify Deployment

Check deployment status:
```bash
oc get all -n contact
```

Check pods are running:
```bash
oc get pods -n contact
```

Get the application route:
```bash
oc get route stt-contact-management -n contact
```

View logs:
```bash
oc logs -f deployment/stt-contact-management -n contact
```

## Components Deployed

### Namespace
- `contact` - Isolated namespace for the application

### PostgreSQL Database
- Deployment with persistent storage (1Gi)
- Service (ClusterIP)
- Uses OCP storage class: `ocs-storagecluster-cephfs`

### Microservice (MSR)
- Deployment with Rolling Update strategy
- Service (ClusterIP with ClientIP affinity)
- Route with TLS edge termination
- HorizontalPodAutoscaler (1-3 replicas, 90% CPU target)
- ServiceMonitor for Prometheus metrics

### Secrets Created
- `regcred` - Image pull secret for GitHub Container Registry
- `postgres` - Database credentials
- `stt-contact-management` - Microservice configuration (DB, Event Streams, EEM, SAG Cloud)
- `es-truststore` - Event Streams TLS certificate
- `eem-truststore` - EEM TLS certificate

## Updating the Deployment

To update the deployment after making changes:

```bash
./deploy.sh
```

The script uses `--dry-run=client` for secrets, so it will update them idempotently.

## Accessing the Application

Get the route URL:
```bash
export ROUTE_URL=$(oc get route stt-contact-management -n contact -o jsonpath='{.spec.host}')
echo "https://${ROUTE_URL}"
```

Test the API:
```bash
curl -k https://${ROUTE_URL}/health
```

## Troubleshooting

### Check pod status
```bash
oc describe pod -l app=stt-contact-management -n contact
```

### Check events
```bash
oc get events -n contact --sort-by='.lastTimestamp'
```

### Check secrets
```bash
oc get secrets -n contact
```

### Check persistent volume
```bash
oc get pvc -n contact
oc describe pvc postgres-pvc -n contact
```

### Access pod shell
```bash
oc exec -it deployment/stt-contact-management -n contact -- /bin/bash
```

## Cleanup

To delete all resources:

```bash
oc delete namespace contact
```

## Security Notes

- **Never commit the `.env` file** - it contains sensitive credentials
- The `.env` file is excluded from git via `.gitignore`
- Routes use TLS edge termination for encrypted traffic
- Secrets are stored as Kubernetes secrets (consider using Vault for production)

## Future Enhancements

- Add production overlay in `overlays/production/` for environment-specific patches
- Integrate with HashiCorp Vault using External Secrets Operator
- Add network policies for enhanced security
- Configure resource quotas and limits
- Add backup strategy for PostgreSQL
