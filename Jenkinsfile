apiVersion: v1
kind: Pod
metadata:
  name: jenkins-agent
spec:
  containers:
  - name: containerd
    image: ghcr.io/containerd/containerd:v1.8.8  # pinned version
    command:
      - tail
      - -f
      - /dev/null  # keeps the container alive for Jenkins exec
    volumeMounts:
      - mountPath: /var/run/containerd
        name: containerd-socket
  volumes:
    - name: containerd-socket
      hostPath:
        path: /var/run/containerd
