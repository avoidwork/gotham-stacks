# Gotham Stacks

This repo contains **prebuilt Kubernetes “stack” manifests** for a homelab.

A **stack** here means: **one YAML file you apply**, and Kubernetes creates everything needed for a related set of apps.

Each stack file is a **single multi-document YAML** (multiple Kubernetes objects separated by `---`). When applied, it typically creates:

- a dedicated **Namespace** (a logical folder for the stack)
- app workloads (usually **Deployments** or **StatefulSets**)
- **Services** (so you can reach the apps)
- storage (either **PVCs** or direct volume mounts)

These manifests are intended to be applied **as-is first**, then customized to match your environment.

---

## Quick start

Apply a stack:

```shell
kubectl apply -f lab.yaml
kubectl apply -f media.yaml
```

Check that resources came up:

```shell
kubectl get ns
kubectl -n lab-stack get all
kubectl -n media-stack get all
```

Remove a stack:

```shell
kubectl delete -f lab.yaml
kubectl delete -f media.yaml
```

---

## How to access the apps (networking)

Most apps are exposed using **NodePort Services**.

That means you can access an app at:

`http://<node-ip>:<nodePort>`

To see the configured ports:

```shell
kubectl -n lab-stack get svc
kubectl -n media-stack get svc
```

---

## Storage: read this before you deploy

This repo uses two common storage patterns:

### 1) PVCs (PersistentVolumeClaims)
Some apps request storage using PVCs, often referencing a StorageClass (for example, `nfs`).

**What you need:** the referenced **StorageClass must already exist** in your cluster.

### 2) NFS mounts inside the pod specs (important for forks/clones)
Some deployments mount volumes via **`nfs`** directly, and they are currently tuned for my homelab:

- **NFS server:** `10.1.2.5`

If you **clone/fork** this repo, you will almost certainly need to **update `server: 10.1.2.5`** to match *your* NAS/NFS server (or switch to PVCs backed by your own StorageClass).

If the NFS server address is wrong or unreachable, pods will usually get stuck starting with mount-related errors.

---

## Secrets (required for some services)

Some workloads expect **Kubernetes Secrets** (usually passwords) to exist **before** you apply the stack.

General pattern (examples):

```shell
kubectl -n lab-stack create secret generic mysql --from-literal=MYSQL_ROOT_PASSWORD="<your-mysql-root-password>"
kubectl -n lab-stack create secret generic mysql --from-literal=MYSQL_NPM_PASSWORD="<your-npm-password>"
kubectl -n lab-stack create secret generic mongodb --from-literal=MONGO_INITDB_ROOT_PASSWORD="<your-mongodb-root-password>"
kubectl -n lab-stack create secret generic influxdb --from-literal=DOCKER_INFLUXDB_INIT_PASSWORD="<your-influxdb-password>"
kubectl -n lab-stack create secret generic teamcity --from-literal=TEAMCITY_DB_PASSWORD="<your-teamcity-db-password>"
kubectl -n lab-stack create secret generic pihole --from-literal=PIHOLE_PASSWORD="<your-pihole-password>"
```

If a required secret is missing, the related pods will typically fail to start. Troubleshoot with:

```shell
kubectl -n describe pod
kubectl -n get events --sort-by=.lastTimestamp
```

---

## What’s in this repo

### `lab.yaml` — Lab Stack

A general-purpose “lab” environment: databases, platform tools, monitoring, and utilities.

**Creates (high level):**
- **Namespace:** `lab-stack`
- **Storage:** multiple PVCs for apps that need persistence
- **Datastores:** MySQL, Redis, MongoDB (replica set + init job)
- **Platform apps:** nginx, SearXNG, Open WebUI, n8n, TeamCity, Nginx Proxy Manager
- **Monitoring:** Grafana, InfluxDB, Prometheus
- **Utilities/exporters:** Pi-hole exporters

### `media.yaml` — Media Stack

Media management and downloading tools.

**Creates (high level):**
- **Namespace:** `media-stack`
- **Apps:** Prowlarr, Lidarr, Radarr, Sonarr, Sabnzbd, Transmission
- **Networking:** each app exposed via **NodePort**
- **Storage:** app configs and media/download paths are mounted for persistence (see the NFS note above)

---

## Customization tips

- **NodePort:** great for homelabs; access apps via `http://<node-ip>:<nodePort>`.
- **Timezone / IDs:** some containers use `TZ`, `PUID`, and `PGID`. Adjust to match your environment.
- **Cluster DNS differences:** some pods set explicit DNS settings; if your cluster setup differs, you may need to adjust those.
- **More portability:** if you want easier migration across clusters/nodes, prefer **PVCs backed by shared storage** over node-specific paths.

---

## Reference: example homelab environment

These manifests were designed around a specific homelab setup (so expect to tweak things):

### Cluster host
- CPU: AMD Epyc 4464P (12c/24t)
- RAM: 128 GiB
- Host OS: Proxmox 9
- Network: bonded 25 GbE (50 GbE)

### Kubernetes nodes (3x VMs)
- OS: Ubuntu Server 24.04 LTS (microk8s)
- CPU: 8 threads
- RAM: 24 GiB
- Disk: 256 GiB

**Node IPs:**
- `10.1.2.50`
- `10.1.2.51`
- `10.1.2.52`

### DNS (Pi-hole)
Local DNS uses `kube.lan` plus per-node hostnames like `kube-N.lan`.

- `10.1.2.2`
- `10.1.2.3`

### NFS Server

- `10.1.2.5`