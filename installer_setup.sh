#!/bin/env bash

#curl -ksSL https://get.docker.com | sudo bash
set -vx
#sudo systemctl enable docker
#sudo systemctl start docker
username=johnkday-k8s-l2
sudo kubeadm init --token=444444.1111111111111111 --service-cidr 10.254.0.0/16 #&& \
ssh  ${username}-vm-2 -o "BatchMode yes" -o "StrictHostKeyChecking no" -T -t "sudo kubeadm join --token=444444.1111111111111111 15.29.33.126" && \
ssh  ${username}-vm-3 -o "BatchMode yes" -o "StrictHostKeyChecking no" -T -t "sudo kubeadm join --token=444444.1111111111111111 15.29.33.126" && \
ssh  ${username}-vm-4 -o "BatchMode yes" -o "StrictHostKeyChecking no" -T -t "sudo kubeadm join --token=444444.1111111111111111 15.29.33.126" && echo created kube cluster


image=1.0.0-beta.3

docker pull contiv/install:${image}

curl -ksSL https://github.com/contiv/install/releases/download/${image}/contiv-${image}.tgz | tar zxf - -C /home/admin

# For ACI on K8s
echo $'sudo ./install/k8s/install.sh -n "15.29.33.126" -v net2' > /home/admin/contiv-${image}/runme.sh

#echo './install/ansible/install_swarm.sh -f ~/settings/cfg.yml -e ~/.ssh/id_rsa -u admin -m aci -v "contiv/aci-gw:02-02-2017.2.1_1h" ' > /home/admin/contiv-${image}/runme.sh


#echo './install/ansible/install_swarm.sh -f ~/settings/cfg.yml -e ~/.ssh/id_rsa -u admin -i ' > /home/admin/contiv-${image}/runme.sh

chmod +x /home/admin/contiv-${image}/runme.sh

sudo cp /home/admin/contiv-${image}/netctl /usr/local/bin/.
sudo cp -rp /home/admin/contiv-${image} /root/

kubectl get nodes
