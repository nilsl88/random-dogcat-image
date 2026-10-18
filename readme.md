# 🐶🐱 Random dog and cat image demo

A static website for random dog and cat pictures, served by Caddy. The browser fetches pictures from Dog CEO and The Cat API. The page shows the serving container's hostname and includes light/dark themes and optional snow and confetti effects.

The container image supports `linux/amd64` and `linux/arm64`. Kubernetes manifests are included for k0s with nginx and k3s with Traefik.

## 🛡️ Container runtime

The image uses `registry.access.redhat.com/hi/caddy:2-builder` from Red Hat [Project Hummingbird](https://hummingbird-project.io/docs/using/overview/). This base includes a shell, core utilities, `sed`, and a package manager. The base-image switch does not guarantee zero vulnerabilities; base updates still require rebuilding and redeploying the image.

At startup, `entrypoint.sh` reads the container hostname from `/proc/sys/kernel/hostname`, creates writable directories under `/tmp`, copies the site to `/tmp/caddy-site`, and replaces `$REPLACE` in the copied HTML. It then uses `exec` to make Caddy PID 1, loading the bundled `/usr/share/caddy/Caddyfile` and serving files from `/tmp/caddy-site`.

The container runs as UID/GID `10001:10001` and listens on port `8080`. It supports a read-only root filesystem with an 8 MiB writable `/tmp` mount.

## 📦 Build locally

Build for the local architecture, refreshing the base image tags:

```bash
podman build --pull=always -t random-dogcat:latest .
```

Build a manifest containing both supported architectures:

```bash
podman build --pull=always \
  --platform linux/amd64,linux/arm64 \
  --manifest random-dogcat:multi \
  .
```

Cross-architecture builds require emulation or builders that support both platforms. Pulling the base tags during a build picks up published base-image updates; it does not update existing images or running containers.

To publish the manifest, authenticate to a registry account with write access and use a destination repository you control:

```bash
podman manifest push --all \
  random-dogcat:multi \
  docker://docker.io/<DOCKERHUB_USER>/random-dogcat:latest
```

## ▶️ Run locally

Run the public image with a read-only filesystem, all capabilities dropped, and privilege escalation blocked:

```bash
podman run -d \
  --name random-dogcat \
  --user 10001:10001 \
  -p 8080:8080 \
  --read-only \
  --cap-drop=all \
  --security-opt=no-new-privileges \
  --tmpfs /tmp:rw,size=8m \
  docker.io/lundberg88/random-dogcat:latest
```

Open [http://localhost:8080](http://localhost:8080). To run your local build, replace the final image name with `random-dogcat:latest`.

## ✅ Verify the container

After building the local image, run the smoke test:

```bash
CONTAINER_ENGINE=podman scripts/smoke-test.sh random-dogcat:latest
```

## ☸️ Run in Kubernetes

For k0s with an nginx ingress controller:

```bash
kubectl apply -f workload-k3s.yaml
kubectl get pods -n dogcat
```

For k3s with Traefik, apply `workload-k3s.yaml` instead. Both manifests configure the same workload in the `dogcat` namespace, including UID/GID `10001:10001`, a read-only root filesystem, dropped capabilities, and an 8 MiB memory-backed `/tmp` volume.

To access the service directly:

```bash
kubectl port-forward -n dogcat svc/random-dogcat-service 8080:80
```

Open [http://localhost:8080](http://localhost:8080).

## 🔗 Container image

The published image is available on [Docker Hub](https://hub.docker.com/r/lundberg88/random-dogcat).
