#!/bin/bash

kubectl apply -f kubernetes/csidriver-new.yaml
kubectl apply -f kubernetes/csi-launcher-new.yaml
kubectl apply -f kubernetes/csi-node-rbac.yaml
kubectl apply -f kubernetes/csi-node-new.yaml

kubectl apply -f kubernetes/secret.yaml
