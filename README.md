# Gotham Stacks

This repo contains **prebuilt Kubernetes manifest bundles** for homelab-style “stacks”. Each file is intended to be applied as-is (a single multi-document YAML) and will create its own Namespace plus the related Deployments/StatefulSets/Services.

## Files

### `lab.yaml` — **Lab Stack**
A consolidated manifest for a general-purpose “lab” environment.

**What it creates (high level):**
- **Namespace:** `lab-stack`
- **Storage:** several `PersistentVolumeClaim`s (for select apps)
- **Datastores:**
    - MySQL (`Deployment` + `Service` via `NodePort`)
    - Redis (`Deployment` + `Service` via `NodePort`)
    - MongoDB replica set (`StatefulSet` + headless `Service` + `NodePort` `Service` + init `Job`)
- **Platform apps:**
    - nginx
    - SearXNG
    - Open WebUI
    - n8n
    - TeamCity
    - Nginx Proxy Manager
- **Monitoring:**
    - Grafana
    - InfluxDB
    - Prometheus
- **Utilities / exporters:** (example: Pi-hole exporters)

**How it’s exposed:**

Most apps are exposed using **`NodePort`** Services. After applying, you can list the ports with: `kubectl -n lab-stack get svc`

**Dependencies / assumptions:**
- A working Kubernetes cluster and `kubectl` context.
- Storage classes referenced by the PVCs must exist in your cluster (for example, an NFS-backed class for RWX claims).
- Some components expect **Kubernetes Secrets** to already exist (e.g., DB credentials). Create them before applying (see “Secrets” below).
- Some workloads use `hostPath` volumes; ensure those directories exist on the node(s) that will run the pods.

---

### `media.yaml` — **Media Stack**
A consolidated manifest for media-management and download services.

**What it creates (high level):**
- **Namespace:** `media-stack`
- **Deployments:** Prowlarr, Lidarr, Radarr, Sonarr, Sabnzbd, Transmission
- **Services:** each app exposed via **`NodePort`**

**Data persistence:**
This stack uses `hostPath` mounts for `/config` and media/download folders. Ensure the mapped directories exist on the node(s) where these pods run.

**Check what ports are in use:** `kubectl -n media-stack get svc`

## Usage

### Apply a stack

```
kubectl apply -f lab.yaml
kubectl apply -f media.yaml
```

### Verify resources

```
kubectl get ns
kubectl -n lab-stack get all
kubectl -n media-stack get all
```

### Remove a stack

```
kubectl delete -f lab.yaml
kubectl delete -f media.yaml
```

## Secrets (required for some services)

Some resources reference secrets (for example, database passwords). Create them **before** applying the stack(s). Example patterns:

```shell
kubectl -n lab-stack create secret generic mysql  --from-literal=MYSQL_ROOT_PASSWORD="<your-mysql-root-password>"
kubectl -n lab-stack create secret generic mongodb --from-literal=MONGO_INITDB_ROOT_PASSWORD="<your-mongodb-root-password>"
kubectl -n lab-stack create secret generic influxdb --from-literal=DOCKER_INFLUXDB_INIT_PASSWORD="<your-influxdb-password>"
kubectl -n lab-stack create secret generic teamcity --from-literal=TEAMCITY_DB_PASSWORD="<your-teamcity-db-password>"
kubectl -n lab-stack create secret generic pihole --from-literal=PIHOLE_PASSWORD="<your-pihole-password>"
```

## Notes / customization tips

- **NodePort access:** reach services at `http://<node-ip>:<nodePort>`.
- **hostPath volumes:** these tie workloads to specific nodes. For multi-node clusters, consider switching to PVCs + a shared storage class.
- **Timezone / IDs:** several containers use `TZ`, `PUID`, and `PGID`. Adjust to match your environment.
- **DNS config:** manifests may include explicit DNS settings; change them if your cluster DNS differs.
- **Nginx Proxy Manager:** Proxies must be pointed at a cluster IP due to a DNS issue in the nginx instance in the pod.
- **TeamCity:** Installation requires accessing the server log to retrieve the token required to complete the installation from the web interface.
- **n8n & Open WebUI:** DGX Spark with Ollama is in the host network.
- **storageClass nfs:** Configuration of an NFS storage class is expected.

## Cluster Host

- CPU: AMD Epyc 4464P (12 core / 24 thread)
- Memory: 128 GiB
- Host OS: Proxmox 9
- Network: Bonded 25 GbE (50 GbE)

### Node (3x)

- Virtual Machine: Ubuntu 24.04 LTS with microk8s
- CPU: 8 threads
- Memory: 24 GiB
- Disk: 256 GiB

#### IPs

- `10.1.2.50`
- `10.1.2.51`
- `10.1.2.52`

#### NFS Mounts

- `/mnt/docker`
- `/mnt/downloads`
- `/mnt/movies`
- `/mnt/music`
- `/mnt/translate`
- `/mnt/tv`

## DNS (pihole)

Local DNS settings have `kube.lan` with all IPs registered, and `kube-N.lan` for specific nodes.

- `10.1.2.2`
- `10.1.2.3`
