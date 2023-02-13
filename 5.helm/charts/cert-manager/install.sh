#!/bin/bash

# 安装cert-manager，它会为我们自动签发免费的 Let’s Encrypt HTTPS 证书，并在过期前自动续期。
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \--namespace cert-manager \--create-namespace \--version v1.11.0 \--set ingressShim.defaultIssuerName=letsencrypt-prod \--set ingressShim.defaultIssuerKind=ClusterIssuer \--set ingressShim.defaultIssuerGroup=cert-manager.io \--set installCRDs=true
kubectl apply -f https://raw.githubusercontent.com/jianchengwang/todo-cloudnative/main/5.helm/charts/cert-manager/cluster-issuer.yaml