# Container images with demo website that display random dog and cat images

Build the image
```bash
podman build -t random-dogcat:latest .
```

Run the public image form dockerhub 
```bash
podman run -d --name random-dogcat -p 8080:80 docker.io/lundberg88/random-dogcat:latest
```

Run the workload in kubernetes
```bash
kubectl apply -f workload.yaml
```
