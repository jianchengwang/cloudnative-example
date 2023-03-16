#!/bin/bash

# git
yum install git
ssh-keygen -t rsa -b 4096 -C "jiancheng_wang@yahoo.com"
cat ~/.ssh/id_rsa.pub
git config --global user.name "jianchengwang"
git config --global user.email "jiancheng_wang@yahoo.com"

# install docker
curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh
sh get-docker.sh
service docker start

# install docker compose
curl -L "https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose version

# install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# create cluster
wget https://raw.githubusercontent.com/jianchengwang/todo-cloudnative/main/1.setup/cluster.yaml
kind create cluster --config cluster.yaml
kubectl apply -f https://raw.githubusercontent.com/jianchengwang/todo-cloudnative/main/1.setup/ingress-nginx.yaml
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
kubectl apply -f https://raw.githubusercontent.com/jianchengwang/todo-cloudnative/main/1.setup/metrics.yaml

# helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash