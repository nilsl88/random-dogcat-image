# Container images with demo website that display random dog and cat images

Build the image
```bash
podman build -t lundberg88/random-dogcat:latest .
```

Run the image
```bash
podman run -d --name random-dogcat -p 8080:80 lundberg88/random-dogcat:latest
```
