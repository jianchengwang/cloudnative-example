## test

### setup

1. [docker](https://docs.docker.com/engine/install/)
2. [kubectl](https://kubernetes.io/docs/tasks/tools/)
3. [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)

### kind create cluster

```shell
$ kind create cluster --config cluster.yaml
$ kind delete cluster
```

### install ingress-nginx

```shell
$ kubectl apply -f ingress-nginx.yaml

# production
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.3.1/deploy/static/provider/cloud/deploy.yaml
$ kubectl get svc -n ingress-nginx
```

### install metric server

```shell
$ kubectl apply -f metrics.yaml
```

## production

1. [kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
2. [kubeasz](https://github.com/easzlab/kubeasz)
3. [KubeOperator](https://github.com/KubeOperator/KubeOperator)
4. [sealos](https://github.com/labring/sealos)
5. [kubesphere](https://github.com/kubesphere/kubesphere)
6. recommand cloud paas