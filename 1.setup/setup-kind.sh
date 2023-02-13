#!/bin/bash

# install docker
curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh
sh get-docker.sh
service docker start

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
kubectl apply -f https://raw.githubusercontent.com/jianchengwang/todo-cloudnative/main/1.setup/metrics.yaml

# git
yum install git
git config --global user.name "jianchengwang"
git config --global user.email "jiancheng_wang@yahoo.com"

# helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash