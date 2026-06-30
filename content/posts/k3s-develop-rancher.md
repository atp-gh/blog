+++
title = "k3s部署rancher"
date = "2024-11-11"
updated = "2024-11-11"
description = "A quick guide to deploying Rancher on k3s."
tags = ["K3s", "Homelab"]
+++

# 安装cert-manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.1/cert-manager.crds.yaml
helm repo add jetstack https://charts.jetstack.io
helm repo update
# kubectl create namespace cert-manager
# helm install cert-manager --namespace cert-manager --version v1.16.1 jetstack/cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
#   --set crds.enabled=true
```

# 安装rancher

```bash
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
kubectl create namespace cattle-system
helm install rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=rancher.my.org \
  --set bootstrapPassword=admin
```

检查安装完成

```bash
kubectl -n cattle-system rollout status deploy/rancher
```

默认部署3台
可以通过参数更改

```bash
helm upgrade rancher rancher-latest/rancher \
  --namespace cattle-system \
  --set hostname=<IP_OF_LINUX_NODE>.sslip.io \
  --set replicas=1 \
  --set bootstrapPassword=<PASSWORD_FOR_RANCHER_ADMIN>

```


## 参考:

1. https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/install-upgrade-on-a-kubernetes-cluster
2. https://artifacthub.io/packages/helm/rancher-stable/rancher
3. https://helm.sh/docs/intro/install/
4. https://artifacthub.io/packages/helm/cert-manager/cert-manager
5. https://ranchermanager.docs.rancher.com/getting-started/quick-start-guides/deploy-rancher-manager/helm-cli
6. https://cert-manager.io/docs/installation/helm/
7. https://docs.rancherdesktop.io/how-to-guides/rancher-on-rancher-desktop/
