#!/bin/bash

# install sealos
wget https://github.com/labring/sealos/releases/download/v4.1.7/sealos_4.1.7_linux_amd64.tar.gz \
   && tar zxvf sealos_4.1.7_linux_amd64.tar.gz sealos && chmod +x sealos && mv sealos /usr/bin
rm -rf ./sealos_4.1.7_linux_amd64.tar.gz

# install k8s single
# sealos version must >= v4.1.0
sealos run labring/kubernetes:v1.25.0 labring/helm:v3.8.2 labring/calico:v3.24.1 --single
# 单节点部署，移除污点，kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# install ingress-nginx, metrics
kubectl apply -f https://raw.githubusercontent.com/jianchengwang/todo-cloudnative/main/1.setup/ingress-nginx.yaml
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
kubectl apply -f https://raw.githubusercontent.com/jianchengwang/todo-cloudnative/main/1.setup/metrics.yaml

# install docker
curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh
sh get-docker.sh
rm -rf ./get-docker.sh
service docker start

# install docker compose
curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose version

# git
yum install git
git config --global user.name "jianchengwang"
git config --global user.email "jiancheng_wang@yahoo.com"

# helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash