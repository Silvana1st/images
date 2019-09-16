#!/bin/bash

echo "\n\nWARNING: If the following disk usage is above 85% then problems will occur..."
df -h / --output=pcent | tail -1
echo "\n\n"

setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

systemctl stop firewalld

modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

cat >> /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
EOF

yum remove kubernetes kubernetes-master kubernetes-node kubernetes-client -y

yum install kubeadm docker -y
systemctl restart docker && systemctl enable docker
systemctl restart kubelet && systemctl enable kubelet

#docker stop `docker ps -a | cut -c 1-12`
#docker rm `docker ps -a | cut -c 1-12`

swapoff -a

kubeadm reset -f
kubeadm init

kubectl taint nodes --all node-role.kubernetes.io/master-

cp /etc/kubernetes/admin.conf ~$USERNAME/.kube/config

kubever=$(kubectl version | base64 | tr -d '\n')
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"

#kubectl run discovery --image=dc243cam/dceks --port=6901
#kubectl expose deployment discovery --type=NodePort
