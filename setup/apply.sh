#!/bin/bash

echo "Applying Calico manifest"
cd "$(dirname "$0")"
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.4/manifests/tigera-operator.yaml
kubectl create -f calico-manifest/custom-resources.yaml
kubectl get pods --all-namespaces
ln -s /etc/rancher/k3s/k3s.yaml ~/.kube/config
calicoctl apply -f calico-manifest/bgppeer.yaml
calicoctl apply -f calico-manifest/bgpconfig.yaml

echo "Show Network Status"
calicoctl get nodes -o wide
calicoctl get bgpPeer -o wide
calicoctl get ippool -o wide
calicoctl get bgpConfiguration -o wide
kubectl get pod -A -o wide

echo "Installing ArgoCD"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/technotut/k3s/main/setup/argocd/install.yaml
argocd admin initial-password -n argocd

echo "Continue with the following command to setup ArgoCD"
echo "argocd login localhost:30001"
echo "argocd account update-password"
echo "Access https://localhost:30001 and login with the password"