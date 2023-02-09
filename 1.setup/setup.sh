#!/bin/bash

# install docker
yum install docker
service docker start

# install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mkdir -p ~/.local/bin
sudo mv ./kubectl ~/.local/bin/kubectl

# install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# create cluster
wget https://raw.githubusercontent.com/jianchengwang/todo-cloudnative/main/1.setup/cluster.yaml
kind create cluster --config cluster.yaml
kubectl apply -f https://raw.githubusercontent.com/jianchengwang/todo-cloudnative/main/1.setup/ingress-nginx.yaml
kubectl apply -f https://raw.githubusercontent.com/jianchengwang/todo-cloudnative/main/1.setup/metrics.yaml
