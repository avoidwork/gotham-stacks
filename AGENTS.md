# AGENTS.md

Rules and principles for agents working on **this** project.

---

## 1. Core Rules

### 1.0 Document Conventions

When updating this document, append new information or sections. Do NOT delete or overwrite existing content unless explicitly directed.

### 1.1 Forbidden Patterns

The following are **strictly prohibited**:

- Hardcoded passwords, keys, or credentials in Helm `values.yaml` files or templates.
- Committing plaintext secrets via `helm template` output or applied manifests to version control.
- Using `helm --set` with sensitive values in CI/CD pipelines or commit messages.
- Storing Helm release state (`kube-state`, `secrets-store-csi-driver` tokens) unencrypted in Git.

### 1.2 Security Rules

- All secrets must be created as Kubernetes `Secret` resources before applying stacks that reference them.
- Never store Helm release state (`helm secret`, `secrets-store-csi-driver` tokens) unencrypted in Git.
- Do not hardcode service credentials in Helm values or manifests — reference existing secrets.
- Validate all outbound tool URLs against an allowlist. Disallow `file://`, `gopher://`, `dict://` schemes.

### 1.3 Git Operations

- **Never rebase under any circumstance without explicit agreement from the user.**
- **Never push to any branch without explicit user approval.** Always ask before running `git push`.
- Never force push.

### 1.4 Core Principles

- **DRY**: Extract repeated logic into functions, classes, or utilities.
- **KISS**: Prefer simple, readable code over clever solutions.
- **YAGNI**: Do NOT build features, abstractions, or configurations not required by the current spec.
- **Single Responsibility**: Each module, class, and function must have one reason to change.

---

## 2. Project Context

### 2.0 Expected Project Layout

```
k8s/
  lab.yaml          — Lab stack (databases, platform tools, monitoring, utilities)
  media.yaml        — Media stack
  docker/
    lab/              — Lab stack (Docker Compose)
      docker-compose.yaml
      init.sh
      mysqld.cnf
    media/
      docker-compose.yaml — Media stack (Docker Compose alternative)
AGENTS.md         — This file
```

### 2.1 Quick Commands

| Command                   | Purpose |
|---------------------------|---------|
| `kubectl apply -f k8s/lab.yaml` | Apply lab stack |
| `kubectl apply -f k8s/media.yaml` | Apply media stack |
| `kubectl delete -f k8s/lab.yaml` | Remove lab stack |
| `kubectl delete -f k8s/media.yaml` | Remove media stack |
| `cd docker/media && docker compose up -d` | Start media stack (Docker Compose) |
| `kubectl -n lab-stack get svc` | List lab stack services |
| `kubectl -n media-stack get svc` | List media stack services |

---

## 3. Environment Conventions

### 3.1 NFS Server (Critical)

The manifests are configured for a specific NFS server:

- **Server IP:** `10.1.2.5`
- **Paths:** Various `/mnt/docker/*` and media paths

**When working on forks/clones:** Update `server: 10.1.2.5` to match your NFS/NAS server, or switch to PVCs backed by your own StorageClass.

### 3.2 Required Secrets

```bash
kubectl -n lab-stack create secret generic mysql --from-literal=MYSQL_ROOT_PASSWORD="<password>"
kubectl -n lab-stack create secret generic npm --from-literal=MYSQL_NPM_PASSWORD="<password>"
kubectl -n lab-stack create secret generic mongodb --from-literal=MONGO_INITDB_ROOT_PASSWORD="<password>"
kubectl -n lab-stack create secret generic influxdb --from-literal=DOCKER_INFLUXDB_INIT_PASSWORD="<password>"
kubectl -n lab-stack create secret generic teamcity --from-literal=TEAMCITY_DB_PASSWORD="<password>"
kubectl -n lab-stack create secret generic pihole --from-literal=PIHOLE_PASSWORD="<password>"
kubectl -n lab-stack create secret generic arc --from-literal=ARC_DB_PASSWORD="<password>"
```

### 3.3 StorageClasses

- `microk8s-hostpath` — Used for PVCs with ReadWriteOnce access
- `nfs` — Used for PVCs with ReadWriteMany access

Ensure these StorageClasses exist in your cluster before applying.

### 3.4 Docker Compose

For media-stack only, there is a Docker Compose alternative that uses bind mounts instead of direct NFS mounts.

**Prerequisites:** The NFS share must be mounted on the Docker host (e.g., `10.1.2.5:/docker /mnt/docker nfs`).

**Commands:**

```bash
cd docker/media
docker compose up -d      # Start all services
docker compose down       # Stop and remove
```

Apps are accessible at `http://<host-ip>:<port>` — each service maps directly to its container port.

---

## 4. Kubernetes Conventions

### 4.1 Stack Structure

Each "stack" is a single multi-document YAML file where applying one file creates everything needed for a related set of apps.

**Lab stack (`lab.yaml`)**
- Namespace: `lab-stack`
- Apps: MySQL, Redis, MongoDB, nginx, SearXNG, Open WebUI, n8n, TeamCity, Nginx Proxy Manager, Grafana, InfluxDB, Prometheus, Pi-hole exporters, OpenClaw (AI agent gateway for WhatsApp, Telegram, Discord, iMessage)

**Media stack (`media.yaml`)**
- Namespace: `media-stack`
- Apps: Prowlarr, Lidarr, Radarr, Sonarr, Sabnzbd, Transmission

### 4.2 Accessing Apps

Apps use NodePort Services. Access at `http://<node-ip>:<nodePort>`

```bash
kubectl -n lab-stack get svc
kubectl -n media-stack get svc
```

### 4.3 Checking Resources

```bash
kubectl get ns
kubectl -n lab-stack get all
kubectl -n media-stack get all
```

---

## 5. Git Conventions

### 5.1 Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: <description>
fix: <description>
docs: <description>
test: <description>
chore: <description>
```

### 5.2 Branching

- Feature branches: `feat/<short-desc>` or `fix/<short-desc>`.
- Never commit directly to `main`. Always create a feature branch first, then open a PR targeting `main`.

### 5.3 Agent Workflow

When auditing or modifying AGENTS.md (or any file):
1. Create a feature branch: `git checkout -b docs/<short-desc>` (or `feat/`, `fix/`).
2. Make changes and commit on the feature branch.
3. Push the feature branch and open a PR with `gh pr create --base main`.
4. Never commit or push directly to `main` or `master`.

---

## 6. Operational Rules

### 6.1 Troubleshooting

**Pods stuck in Pending/ContainerCreating:**
- Check for NFS mount errors: `kubectl -n <namespace> describe pod <pod>`
- Verify NFS server is reachable
- Check StorageClass exists: `kubectl get sc`

**Pods failing to start (secret issues):**
- Verify required secrets exist: `kubectl -n <namespace> get secrets`
- Check events: `kubectl -n <namespace> get events --sort-by=.lastTimestamp`

**DNS issues:**
Some pods use `hostNetwork: true` with custom DNS settings. If your cluster DNS differs, you may need to adjust `dnsConfig` in affected pods.

---

## 7. Session Learnings

### 7.1 Customization Notes

- **Timezone:** `America/Toronto` is used throughout; update `TZ` env vars as needed
- **User/Group IDs:** `PUID=1000`, `PGID=1000` are common; adjust for your environment
- **Node selection:** Some apps (nginx-proxy-manager) have `nodeSelector` for specific nodes
- **Cluster DNS:** MicroK8s uses `10.152.183.10`; update for other clusters

---

## 8. Reference Environment

- **Kubernetes:** MicroK8s on Ubuntu 24.04 LTS
- **Nodes:** 3 VMs (kube-1, kube-2, kube-3)
- **DNS:** Pi-hole at 10.1.2.2 and 10.1.2.3
- **NFS:** 10.1.2.5
