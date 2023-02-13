#!/bin/bash

helm repo add harbor https://helm.goharbor.io
helm repo update
helm install harbor harbor/harbor -f values.yaml --namespace harbor --create-namespace
kubectl wait --for=condition=Ready pods --all -n harbor --timeout 600s
# 需要为域名配置 DNS 解析。首先，获取 Ingress-Nginx Loadbalancer 的外网 IP。
kubectl get services --namespace ingress-nginx ingress-nginx-controller --output jsonpath='{.status.loadBalancer.ingress[0].ip}'
# 查看证书是否已经签发
kubectl get certificate -A

# docker login harbor.example.dev
# username: admin
# password: Harbor12345
# Login Succeeded