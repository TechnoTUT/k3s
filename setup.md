# k3s setup
## Install k3s
Install k3s on a single node (master and worker) with the following command:
```bash
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--flannel-backend=none --cluster-cidr=10.244.0.0/16 --disable-network-policy --disable=traefik" sh -
```
## Network settings
Install Calico
```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.4/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/technotut/k3s/main/calico-manifest/custom-resources.yaml
```
Confirm that all of the pods are running using the following command:
```bash
watch kubectl get pods --all-namespaces
```
Install Calicoctl and configure
```bash
cd /usr/local/bin
curl -L https://github.com/projectcalico/calico/releases/download/v3.26.4/calicoctl-linux-amd64 -o calicoctl
sudo chmod +x ./calicoctl
ln -s /etc/rancher/k3s/k3s.yaml ~/.kube/config
calicoctl apply -f https://raw.githubusercontent.com/technotut/k3s/main/calico-manifest/bgppeer.yaml
calicoctl apply -f https://raw.githubusercontent.com/technotut/k3s/main/calico-manifest/bgpconfig.yaml
```
Configure Router
```
## NEC IX, Cisco IOS
enable
configure terminal (only Cisco)
router bgp 65000
neighbor <server-ip> remote-as 65000
exit
write memory
show ip bgp summary
```
Router says "ESTABLISHED", It works!

Confirm network settings
```bash
calicoctl get nodes -o wide
calicoctl get bgpPeer -o wide
calicoctl get ippool -o wide
calicoctl get bgpConfiguration -o wide
watch kubectl get pod -A -o wide
```

## Setup Persistent Volume using nfs-subdir-external-provisioner
nfs-subdir-external-provisioner: https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner  
Install nfs server
```bash
mkdir /nfs
dnf install nfs-utils
systemctl enable --now nfs-server
vim /etc/exports
```
``` /etc/exports
/nfs localhost(rw,no_root_squash)
```
```bash
exportfs -a
exportfs
firewall-cmd --add-service=nfs --permanent
firewall-cmd --reload
```
Install Helm
```bash
cd /usr/local/bin
wget https://get.helm.sh/helm-v3.13.2-linux-amd64.tar.gz
tar -zxvf helm-v3.13.2-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm 
```
Install nfs-subdir-external-provisioner
```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --set nfs.server=localhost --set nfs.path=/nfs
```

## if you want to reset
k3s uninstall and retry install
```bash
/usr/local/bin/k3s-uninstall.sh
```