
# gitJenkinTerraform

This project demonstrates a Jenkins pipeline using Docker, Kubernetes (MicroK8s), and Terraform, including unit testing, build, security checks, and deployment.

Pipeline Flow: Unit Test → Build → Terraform Validate → Security → Deploy
---

## Prerequisites

* Docker installed locally
* MicroK8s installed and running
* MicroK8s registry enabled (`microk8s enable registry`)
* `kubectl` configured via MicroK8s:


* Jenkins installed via Kubernetes manifests (see below)

---

## 1. Build the Docker Image

For MicroK8s, push images to the local registry at `localhost:32000` (default MicroK8s registry):

```bash
docker build -t localhost:32000/gitjenkinterraform:latest .
```

---

## 2. Push Docker Image to MicroK8s Registry

```bash
docker push localhost:32000/gitjenkinterraform:latest
```

> No credentials are required. The MicroK8s registry is local and accessible to all pods in the cluster.

---

## 3. Make the Docker Image Accessible in Kubernetes Jenkins (MicroK8s)

MicroK8s nodes can pull images from `localhost:32000` directly. To verify:

```bash
microk8s kubectl run test-pod --image=localhost:32000/gitjenkinterraform:latest --restart=Never --rm -it -- bash
```

If the pod starts successfully, Kubernetes can access the image.

> **Note:** If you installed MicroK8s on a VM or remote host, replace `localhost` with the host IP accessible by the cluster.

---

## 4. Apply Kubernetes Manifests (Correct Order)

Apply Jenkins manifests **in this order**:

```bash
microk8s kubectl apply -f jenkins-ca-configmap.yaml
microk8s kubectl apply -f jenkins-rbac.yaml
microk8s kubectl apply -f jenkins-sa.yaml
microk8s kubectl apply -f jenkins-pvc.yaml
microk8s kubectl apply -f jenkins-deployment.yaml
microk8s kubectl apply -f jenkins-service.yaml
```

> Order is important to ensure RBAC, service accounts, and storage are ready before the Jenkins deployment.

---

## 5. Login to Jenkins

Get the default admin password:

```bash
microk8s kubectl exec --namespace default -it <jenkins-pod-name> -- cat /var/jenkins_home/secrets/initialAdminPassword
```

* Open: `http://<jenkins-service-ip>:32043`
* Use the password above to log in
* Install suggested plugins

---

## 6. Configure Jenkins Cloud & Pod Templates

1. Go to **Manage Jenkins → Manage Nodes and Clouds → Configure Clouds**
2. Add a **Kubernetes cloud**:

   * Kubernetes URL: `https://kubernetes.default.svc`
   * Namespace: `default`
3. Add **Pod Templates** matching the YAML files in `jenkins/pod-templates/`:

   * `python`, `terraform`, `security-tools`, etc.
   * Containers use the MicroK8s registry images (e.g., `localhost:32000/gitjenkinterraform:latest`)

---

## 7. Run the Jenkins Pipeline

Pipeline stages:

1. Debug
2. Unit Tests → runs `pytest`
3. Build
4. Terraform Validate
5. Terraform Security → Checkov
6. Deploy → runs `python -m src.app 3 5`

**Expected results:**

* All stages green ✅
* Unit tests pass
* Terraform validation succeeds
* Checkov failure ≤ 10%
* Deploy runs the application

---

✅ **Note for MicroK8s Users:**

* The local registry at `localhost:32000` is automatically available to all pods.
* No registry credentials or special configuration are required.
* If using MicroK8s on a VM, ensure pods can reach the host IP for the registry.


# Cleaning / Resetting the Environment

For repeated runs, users may want to clean old pods, PVCs, or images:

kubectl delete -f jenkins-deployment.yaml
kubectl delete pvc jenkins-pvc
docker rmi localhost:32000/gitjenkinterraform:latest


Useful tip for local development.

# Troubleshooting Tips

Image pull fails → check localhost:32000 accessibility.

# Pipeline fails → check pod logs:

kubectl logs <jenkins-pod-name> -c <container-name>


PVC not mounting → verify permissions or storage class.

Useful Commands

Check Jenkins pod status:

kubectl get pods


Access Jenkins service (if NodePort):

kubectl get svc jenkins

Also the Console Output on the Jenkins GUI.