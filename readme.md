# 🐶🐱 Random dog & cat image demo

A simple containerized demo website that serves random dog and cat images.  
Perfect for testing container runtimes, Kubernetes deployments, or just brightening your day with cute animals!

---

## 🚀 Features
- Displays random dog and cat images
- Packaged as a container image (Podman / Docker compatible)
- Ready-to-use Kubernetes deployment manifest (`workload.yaml`)
- Lightweight and fun demo workload

---

## 📦 Build the Image

If you want to build the image locally:

```bash
podman build -t random-dogcat:latest .
````

---

## ▶️ Run the Container

Run the pre-built public image from Docker Hub:

```bash
podman run -d --user 10001:10001 --name random-dogcat -p 8080:80 docker.io/lundberg88/random-dogcat:latest
```

The website will now be available at:
👉 [http://localhost:8080](http://localhost:8080)

---

## ☸️ Run in Kubernetes

Deploy using the provided Kubernetes manifest:

```bash
kubectl apply -f workload-k0s.yaml
```

Check that the pod is running:

```bash
kubectl get pods -n dogcat
```

Then, expose it (if not already exposed):

```bash
kubectl port-forward svc/random-dogcat 8080:80
```

Access the site at:
👉 [http://localhost:8080](http://localhost:8080)

---

## 🔗 Container Image

Available on Docker Hub:
[**lundberg88/random-dogcat**](https://hub.docker.com/r/lundberg88/random-dogcat)
