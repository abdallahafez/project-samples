# 🧩 Kubernetes Nginx Deployment and Service Examples

This repository contains simple **Kubernetes YAML manifests** demonstrating how to deploy and expose applications inside a Kubernetes cluster without using an Ingress controller.

---

## 📄 Files Overview

### 🌀 `deployment.yaml`
Defines a Deployment running **3 replicas** of an Nginx container.  
Each pod serves a custom HTML page that displays its own Pod name.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-sample
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-sample
  template:
    metadata:
      labels:
        app: nginx-sample
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        command: ["/bin/sh"]
        args:
        - -c
        - |
          echo "<html><body><h1>Hello from pod: ${POD_NAME}</h1></body></html>" > /usr/share/nginx/html/index.html
          nginx -g 'daemon off;'
      volumes:
      - name: html
        emptyDir: {}
```