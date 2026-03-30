# Agent Guidelines for Gotham Stacks

## Project Overview

This repository contains prebuilt Kubernetes "stack" manifests for a homelab environment. A **stack** is a single multi-document YAML file where applying one file creates everything needed for a related set of apps.

## Structure

- **`lab.yaml`** — Lab stack (databases, platform tools, monitoring, utilities)
  - Namespace: `lab-stack`
  - Apps: MySQL, Redis, MongoDB, nginx, SearXNG, Open WebUI, n8n, TeamCity, Nginx Proxy Manager, Grafana, InfluxDB, Prometheus, Pi-hole exporters

- **`media.yaml`** — Media stack (media management and downloading)
  - Namespace: `media-stack`
  - Apps: Prowlarr, Lidarr, Radarr, Sonarr, Sabnzbd, Transmission

## Key Environmental Dependencies

### NFS Server (Critical)
The manifests are configured for a specific NFS server:
- **Server IP:** `10.1.2.5`
- **Paths:** Various `/docker/*` and media paths

**When working on forks/clones:** Update `server: 10.1.2.5` to match your NFS/NAS server, or switch to PVCs backed by your own StorageClass.

### Required Secrets
Before applying stacks, create these secrets:

```bash
# Lab stack secrets
kubectl -n lab-stack create secret generic mysql --from-literal=MYSQL_ROOT_PASSWORD="<password>"
kubectl -n lab-stack create secret generic npm --from-literal=MYSQL_NPM_PASSWORD="<password>"
kubectl -n lab-stack create secret generic mongodb --from-literal=MONGO_INITDB_ROOT_PASSWORD="<password>"
kubectl -n lab-stack create secret generic influxdb --from-literal=DOCKER_INFLUXDB_INIT_PASSWORD="<password>"
kubectl -n lab-stack create secret generic teamcity --from-literal=TEAMCITY_DB_PASSWORD="<password>"
kubectl -n lab-stack create secret generic pihole --from-literal=PIHOLE_PASSWORD="<password>"
kubectl -n lab-stack create secret generic arc --from-literal=ARC_DB_PASSWORD="<password>"
```

### StorageClasses
- `microk8s-hostpath` — Used for PVCs with ReadWriteOnce access
- `nfs` — Used for PVCs with ReadWriteMany access

Ensure these StorageClasses exist in your cluster before applying.

## Common Operations

### Apply a stack
```bash
kubectl apply -f lab.yaml
kubectl apply -f media.yaml
```

### Remove a stack
```bash
kubectl delete -f lab.yaml
kubectl delete -f media.yaml
```

### Check resources
```bash
kubectl get ns
kubectl -n lab-stack get all
kubectl -n media-stack get all
```

### Access apps
Apps use NodePort Services. Access at `http://<node-ip>:<nodePort>`

```bash
kubectl -n lab-stack get svc
kubectl -n media-stack get svc
```

## Troubleshooting

### Pods stuck in Pending/ContainerCreating
- Check for NFS mount errors: `kubectl -n <namespace> describe pod <pod>`
- Verify NFS server is reachable
- Check StorageClass exists: `kubectl get sc`

### Pods failing to start (secret issues)
- Verify required secrets exist: `kubectl -n <namespace> get secrets`
- Check events: `kubectl -n <namespace> get events --sort-by=.lastTimestamp`

### DNS issues
Some pods use `hostNetwork: true` with custom DNS settings. If your cluster DNS differs, you may need to adjust `dnsConfig` in affected pods.

## Customization Notes

- **Timezone:** `America/Toronto` is used throughout; update `TZ` env vars as needed
- **User/Group IDs:** `PUID=1000`, `PGID=1000` are common; adjust for your environment
- **Node selection:** Some apps (nginx-proxy-manager) have `nodeSelector` for specific nodes
- **Cluster DNS:** MicroK8s uses `10.152.183.10`; update for other clusters

## Reference Environment

- **Kubernetes:** MicroK8s on Ubuntu 24.04 LTS
- **Nodes:** 3 VMs (kube-1, kube-2, kube-3)
- **DNS:** Pi-hole at 10.1.2.2 and 10.1.2.3
- **NFS:** 10.1.2.5
