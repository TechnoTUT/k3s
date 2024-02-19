#!/bin/bash

echo "Updating system"
dnf update -y
dnf install -y curl wget git firewalld tar nfs-utils

echo "Installing k3s"
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--flannel-backend=none --cluster-cidr=10.244.0.0/16 --disable-network-policy --disable=traefik" sh -

echo "Installing network plugin"
cd /usr/local/bin
curl -L https://github.com/projectcalico/calico/releases/download/v3.26.4/calicoctl-linux-amd64 -o calicoctl
sudo chmod +x ./calicoctl
firewall-cmd --add-port=179/tcp --permanent
firewall-cmd --add-port=6443/tcp --permanent
firewall-cmd --add-port=10250/tcp --permanent
firewall-cmd --zone=trusted --add-source=10.43.0.0/16 --permanent
firewall-cmd --zone=trusted --add-source=10.244.0.0/16 --permanent
firewall-cmd --zone=trusted --add-source=<client-cidr> --permanent
firewall-cmd --reload

echo "Setup Persistent Volume"
mkdir /nfs
systemctl enable --now nfs-server
cat <<EOF > /etc/exports
/nfs localhost(rw,no_root_squash)
EOF
exportfs -a
exportfs
firewall-cmd --add-service=nfs --permanent
firewall-cmd --reload
echo "Installing Helm"
cd /usr/local/bin
wget https://get.helm.sh/helm-v3.13.2-linux-amd64.tar.gz
tar -zxvf helm-v3.13.2-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm 
echo "Installing NFS Subdir External Provisioner"
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=localhost --set nfs.path=/nfs

echo "Install Kompose"
cd /usr/local/bin
curl -L https://github.com/kubernetes/kompose/releases/download/v1.31.2/kompose-linux-amd64 -o kompose
chmod +x kompose

echo "Install ArgoCD"
cd /usr/local/bin
curl -L https://github.com/argoproj/argo-cd/releases/download/v2.9.2/argocd-linux-amd64 -o argocd
chmod +x argocd
firewall-cmd --add-port=30001/tcp --permanent
firewall-cmd --reload

echo "Execute apply.sh to apply the manifest"