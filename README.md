# Gotham Stacks

This repository provides **prebuilt Kubernetes “stack” manifests** for a homelab. A *stack* here means: **one YAML file you apply**, and Kubernetes creates everything needed for that group of apps.

Each stack file is a **single multi-document YAML** (many Kubernetes objects separated by `---`). When you apply it, it creates:

- a dedicated **Namespace** (a logical “folder” for resources)
- the app workloads (usually **Deployments** or **StatefulSets**)
- **Services** so you can reach the apps on the network
- sometimes **PersistentVolumeClaims (PVCs)** for storage

These manifests are intended to be applied **as‑is**, then customized to match your environment.

---

## What you’ll find in this repo

### `lab.yaml` — Lab Stack

A general‑purpose “lab” environment: databases, common platform tools, monitoring, and utilities.

**Creates (high level):**
- **Namespace:** `lab-stack`
- **Storage:** multiple **PVCs** for apps that need persistent data
- **Datastores:**
  - **MySQL** (Deployment + Service exposed via NodePort)
  - **Redis** (Deployment + Service exposed via NodePort)
  - **MongoDB replica set** (StatefulSet + headless Service + NodePort Service + an init Job)
- **Platform apps:** nginx, SearXNG, Open WebUI, n8n, TeamCity, Nginx Proxy Manager
- **Monitoring:** Grafana, InfluxDB, Prometheus
- **Utilities/exporters:** Pi‑hole exporters

**How you access it (networking):**
Most apps are exposed using **NodePort Services**.

That means you can access an app at:

`http://<node-ip>:<nodePort>`

To see which ports were assigned/configured:

`kubectl -n lab-stack get svc`

**Important assumptions / prerequisites:**
- You have a working Kubernetes cluster and `kubectl` is pointed at it (your “context” is set correctly).
- Any **StorageClasses** referenced by PVCs must already exist in your cluster (for example, an NFS‑backed class if you need ReadWriteMany storage).
- Some components reference **Kubernetes Secrets** (like database passwords). Those secrets must exist *before* you apply the stack.
- Some workloads use **hostPath** volumes (paths on the node’s filesystem). If so, those directories must exist on whichever node the pods land on.

---

### `media.yaml` — Media Stack

A stack focused on media management and downloading tools.

**Creates (high level):**
- **Namespace:** `media-stack`
- **Apps:** Prowlarr, Lidarr, Radarr, Sonarr, Sabnzbd, Transmission
- **Networking:** each app exposed via **NodePort**

**Data persistence:**
This stack uses **hostPath mounts** for config and media/download folders.

That means:
- your data is stored on the Kubernetes node’s filesystem at specific paths
- pods become implicitly tied to nodes where those paths exist
- in multi‑node clusters, you must ensure the same paths exist (and contain the right data) on every node that might run the pod—or constrain scheduling to specific nodes

To see ports in use:

`kubectl -n media-stack get svc`

---

## How to use

### Apply a stack

```shell
kubectl apply -f lab.yaml
kubectl apply -f media.yaml
```

### Verify what was created

```shell
kubectl get ns
kubectl -n lab-stack get all
kubectl -n media-stack get all
```

### Remove a stack

```shell
kubectl delete -f lab.yaml
kubectl delete -f media.yaml
```

---

## Secrets (required for some services)

Some resources expect secrets (typically passwords) to already exist.

Create the required secrets **before** applying the stack.

Example pattern:

```shell
kubectl -n lab-stack create secret generic mysql --from-literal=MYSQL_ROOT_PASSWORD="<your-mysql-root-password>"
kubectl -n lab-stack create secret generic mongodb --from-literal=MONGO_INITDB_ROOT_PASSWORD="<your-mongodb-root-password>"
kubectl -n lab-stack create secret generic influxdb --from-literal=DOCKER_INFLUXDB_INIT_PASSWORD="<your-influxdb-password>"
kubectl -n lab-stack create secret generic teamcity --from-literal=TEAMCITY_DB_PASSWORD="<your-teamcity-db-password>"
kubectl -n lab-stack create secret generic pihole --from-literal=PIHOLE_PASSWORD="<your-pihole-password>"
```

If a secret is missing, the related pods will usually fail to start (you’ll see errors when describing the pod or checking events).

---

## Notes & customization tips

- **NodePort access:** services are reachable at `http://<node-ip>:<nodePort>`.
- **hostPath volumes:** these are simple and fast for homelabs, but they reduce portability. For a more “Kubernetes-native” approach, prefer **PVCs** backed by shared storage.
- **Timezone / IDs:** some containers use `TZ`, `PUID`, and `PGID`. Adjust them to match your user/group setup and local timezone.
- **DNS config:** some manifests may set explicit DNS behavior. If your cluster DNS setup differs, you may need to adjust those settings.
- **Nginx Proxy Manager:** proxy targets may need to point to a specific cluster address depending on DNS/networking behavior in your environment.
- **TeamCity:** first-time setup can require grabbing a token from logs to finish installation via the web UI.
- **StorageClass `nfs`:** an NFS-based StorageClass is expected if PVCs reference it.

---

## Reference: homelab environment (example)

These manifests were designed around a specific homelab setup:

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

### Host paths used by workloads
These are NFS mounts from a NAS, mounted on each node:

- `/mnt/docker`
- `/mnt/downloads`
- `/mnt/movies`
- `/mnt/music`
- `/mnt/translate`
- `/mnt/tv`

### DNS (Pi-hole)
Local DNS uses `kube.lan` for the cluster, plus per-node hostnames like `kube-N.lan`.

- `10.1.2.2`
- `10.1.2.3`