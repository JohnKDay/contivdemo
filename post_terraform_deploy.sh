#!/bin/env bash

# Post terraform deploy to allow for smooth Contiv install
# could be an ansible, but in the interest of time

#cat /home/admin/settings/proxy_env | sudo tee /etc/environment >/dev/null
#cat /home/admin/settings/no_proxy_env | sudo tee -a /etc/environment >/dev/null
sudo cp /dev/null /etc/environment 
sudo systemctl disable firewalld
sudo systemctl stop firewalld

sudo groupadd docker
sudo usermod -aG docker admin

echo "
[kubernetes]
name=Kubernetes
baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
" | sudo tee /etc/yum.repos.d/kubernetes.repo > /dev/null

sudo setenforce 0
sudo yum install -yq docker kubelet kubeadm kubectl kubernetes-cni
sudo systemctl enable docker && sudo systemctl start docker
sudo systemctl enable kubelet && sudo systemctl start kubelet
