# Agent Instructions for Gotham Stacks Kubernetes Repository

This file provides guidance for AI agents working with the Gotham Stacks repository, which contains Helm charts for Kubernetes namespaces.

## Repository Structure

The repository contains two Helm charts:
- `charts/lab-stack/` - For the lab environment namespace
- `charts/media-stack/` - For the media environment namespace

Each chart creates a dedicated namespace and deploys related applications as defined in the bundled manifests (referred to as "stacks" in README.md).

## Standard Operations

### Installing Stacks
To install a stack using Helm:
```shell
helm install lab-stack ./charts/lab-stack
helm install media-stack ./charts/media-stack
```

### Upgrading Stacks
To upgrade an existing release:
```shell
helm upgrade lab-stack ./charts/lab-stack
helm upgrade media-stack ./charts/media-stack
```

### Uninstalling Stacks
To remove a stack:
```shell
helm uninstall lab-stack
helm uninstall media-stack
```

### Viewing Deployed Resources
```shell
kubectl get ns
kubectl -n lab-stack get all
kubectl -n media-stack get all
```

## Chart Customization

Values can be customized by:
1. Editing the `values.yaml` file in each chart directory
2. Using `--set` flags during install/upgrade:
   ```shell
   helm install lab-stack ./charts/lab-stack --set persistence.enabled=false
   ```
3. Creating custom values files:
   ```shell
   helm install lab-stack ./charts/lab-stack -f my-lab-values.yaml
   ```

## Important Notes

### Storage
- Charts use PersistentVolumeClaims (PVCs) by default
- Ensure the referenced StorageClass exists in your cluster
- For NFS-mounted volumes (if enabled), update the server address in values.yaml to match your NAS/NFS server

### Secrets
- Some charts require Kubernetes Secrets to be created before installation
- See README.md for specific secret requirements per application
- Create secrets in the target namespace before installing the chart

### Networking
- Services are configured as NodePort by default for homelab accessibility
- Access applications at `http://<node-ip>:<nodePort>`
- To view configured ports: `kubectl -n <namespace> get svc`

## Development Guidelines

When modifying charts:
1. Keep changes backward compatible where possible
2. Update Chart.yaml version after significant changes
3. Test changes in a development cluster before updating production values
4. Document any breaking changes in the chart's README.md
5. Follow the existing naming conventions for resources and labels

## Troubleshooting

- Check pod status: `kubectl -n <namespace> get pods`
- View logs: `kubectl -n <namespace> logs <pod-name>`
- Describe resources: `kubectl -n <namespace> describe <resource-type> <resource-name>`
- Check events: `kubectl -n <namespace> get events --sort-by=.lastTimestamp`
- Use `helm test <release-name>` to run chart tests if available

## References

See README.md for detailed information about:
- Stack composition and purpose
- Storage requirements and considerations
- Secret requirements
- Networking and access methods
- Customization tips
- Reference homelab environment