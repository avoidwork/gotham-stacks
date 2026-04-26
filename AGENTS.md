# Agent Guidelines for Gotham Stacks

## Project Overview

This repository contains prebuilt Kubernetes "stack" manifests for a homelab environment. A **stack** is a single multi-document YAML file where applying one file creates everything needed for a related set of apps.

## Structure

- **`lab.yaml`** — Lab stack (databases, platform tools, monitoring, utilities)
  - Namespace: `lab-stack`
  - Apps: MySQL, Redis, MongoDB, nginx, SearXNG, Open WebUI, n8n, TeamCity, Nginx Proxy Manager, Grafana, InfluxDB, Prometheus, Pi-hole exporters, OpenClaw (AI agent gateway for WhatsApp, Telegram, Discord, iMessage)

- **`media.yaml`** — Media stack (Kubernetes)
  - Namespace: `media-stack`
  - Apps: Prowlarr, Lidarr, Radarr, Sonarr, Sabnzbd, Transmission
- **`docker-compose.yaml`** — Media stack (Docker Compose alternative)
  - File: `media/docker-compose.yaml`
  - Apps: Same as media.yaml, using bind mounts instead of NFS volumes

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

### Docker Compose (Media Stack Only)
For media-stack only, there is a Docker Compose alternative that uses bind mounts instead of direct NFS mounts.

**Prerequisites:** The NFS share must be mounted on the Docker host (e.g., `10.1.2.5:/docker /docker nfs`).

**Commands:**
```bash
cd media
docker compose up -d      # Start all services
docker compose down       # Stop and remove
```

Apps are accessible at `http://<host-ip>:<port>` — each service maps directly to its container port.

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
