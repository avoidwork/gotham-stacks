# Agent Instructions for Gotham Stacks Kubernetes Repository

This file provides guidance for AI agents working with the Gotham Stacks repository, which contains Kubernetes manifests for namespaces.

## Repository Structure

The repository contains two stack manifest files:
- `lab.yaml` - For the lab environment namespace
- `media.yaml` - For the media environment namespace

Each file creates a dedicated namespace and deploys related applications (referred to as "stacks" in README.md).

## Standard Operations

### Installing Stacks
To install a stack using kubectl:
```shell
kubectl apply -f lab.yaml
kubectl apply -f media.yaml
```

### Upgrading Stacks
To update an existing stack:
```shell
kubectl apply -f lab.yaml
kubectl apply -f media.yaml
```

### Uninstalling Stacks
To remove a stack:
```shell
kubectl delete -f lab.yaml
kubectl delete -f media.yaml
```

### Viewing Deployed Resources
```shell
kubectl get ns
kubectl -n lab-stack get all
kubectl -n media-stack get all
```

## Manifest Customization

Values can be customized by:
1. Editing the YAML files directly (`lab.yaml` or `media.yaml`)
2. Creating custom overlay files and applying them with `kubectl apply -f`
3. Using tools like `kustomize` or `helm` if preferred (though the manifests are designed to be applied directly)

## Important Notes

### Storage
- Manifests use PersistentVolumeClaims (PVCs) by default
- Ensure the referenced StorageClass exists in your cluster
- For NFS-mounted volumes (if enabled), update the server address in the YAML files to match your NAS/NFS server

### Secrets
- Some manifests require Kubernetes Secrets to be created before installation
- See README.md for specific secret requirements per application
- Create secrets in the target namespace before applying the manifest

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