+++
title = "k3s部署kubevirt-manager"
date = "2024-11-08"
updated = "2024-11-08"
description = "A quick guide to deploying kubevirt-manager on k3s."
tags = ["K3s", "Homelab"]
+++

# 安装kubevirt

## 安装qemu_kvm,libvirt

自行安装

```bash
pass
```

## 安装kubectl

自行安装

```bash
pass
```

## 安装kind

自行安装

```bash
pass
```

## 设置默认文件

```bash
mkdir -p /root/.kube
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
kubectl get nodes
```

## 使用kubectl安装kubevirt operator

可以使用 KubeVirt Operator 安装 KubeVirt，该 Operator 管理所有 KubeVirt 核心组件的生命周期

```bash
export VERSION=$(curl -s https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
echo $VERSION
kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-operator.yaml"
```

## 使用 kubectl 部署 KubeVirt 自定义资源定义

```bash
kubectl create -f "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/kubevirt-cr.yaml"
```

## 验证部署

```bash
kubectl get kubevirt.kubevirt.io/kubevirt -n kubevirt -o=jsonpath="{.status.phase}"
```

需要等上一会

```bash
kubectl get all -n kubevirt
```

等到状态为`Deployed`即完成
默认情况下，KubeVirt 将部署 7 个 Pod、3 个服务、1 个 daemonset、3 个部署应用、3 个副本集

## 安装virt (optional)

```bash
kubectl krew install virt
```

# 安装kubevirt-manager

````

# 创建`storageclass.yaml`文件
#
# ```storageclass.yaml
# apiVersion: storage.k8s.io/v1
# kind: StorageClass
# metadata:
#   name: local-path
# provisioner: rancher.io/local-path
# allowVolumeExpansion: true
# volumeBindingMode: WaitForFirstConsumer
````

使用默认配置

```bash
kubectl apply -f https://raw.githubusercontent.com/kubevirt-manager/kubevirt-manager/main/kubernetes/bundled.yaml
```

接下来，获取节点ip进行访问

```bash
kubectl get service kubevirt-manager -n kubevirt-manager
```

输出如下

```
NAME               TYPE       CLUSTER-IP        EXTERNAL-IP   PORT(S)       AGE
kubevirt-manager   NodePort   your-cluster-ip   <none>        8080/TCP      11m
```

or

```bash
git clone https://github.com/kubevirt-manager/kubevirt-manager.git
cd kubevirt-manager
kubectl apply -f kubernetes/ns.yaml
kubectl apply -f kubernetes/crd.yaml
kubectl apply -f kubernetes/rbac.yaml
kubectl apply -f kubernetes/pc.yaml
kubectl apply -f kubernetes/service.yaml
```

为了可以使用节点ip访问virt-manager

将原`kubernetes/service.yaml`

```kubernetes/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: kubevirt-manager
  namespace: kubevirt-manager
  labels:
    app: kubevirt-manager
    kubevirt-manager.io/version: 1.4.1
spec:
  type: ClusterIP
  selector:
    app: kubevirt-manager
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
```

中的 `ClusterIP` 修改为`NodePort`,且可以添加映射出去的端口,修改后如下

```kubernetes/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: kubevirt-manager
  namespace: kubevirt-manager
  labels:
    app: kubevirt-manager
    kubevirt-manager.io/version: 1.4.1
spec:
  type: NodePort
  selector:
    app: kubevirt-manager
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
      nodePort: 30080  # 如果使用 NodePort，可以指定端口号
```

再次应用`kubernetes/service.yaml`

```bash
kubectl apply -f kubernetes/service.yaml
```

接下来，获取节点ip进行访问

```bash
kubectl get service kubevirt-manager -n kubevirt-manager
```

输出如下

```
NAME               TYPE       CLUSTER-IP        EXTERNAL-IP   PORT(S)           AGE
kubevirt-manager   NodePort   your-cluster-ip   <none>        8080:30080/TCP    11m
```

## 参考

1. https://kubevirt.io/user-guide/
2. https://kubevirt-manager.io/get_started.html
