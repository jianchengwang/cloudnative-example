## api对象

因为 apiserver 是 Kubernetes 系统的唯一入口，外部用户和内部组件都必须和它通信，而它采用了 HTTP 协议的 URL 资源理念，API 风格也用 RESTful 的 GET/POST/DELETE 等等，所以，这些概念很自然地就被称为是“API 对象”了。

```shell
$ kubectl api-resources
$ kubectl get pods --v=9
```

![api-resources](./api-resources.webp)


## Imperative & Declarative

```shell
$ kubectl create -f nginx.yaml
$ kubectl delete -f nginx.yaml -f redis.yaml
$ kubectl replace -f nginx.yaml
```

 Declarative object configuration retains changes made by other writers, even if the changes are not merged back to the object configuration file. This is possible by using the patch API operation to write only observed differences, instead of using the replace API operation to replace the entire object configuration.

```shell
$ kubectl diff -R -f configs/
$ kubectl apply -R -f configs/
```

实际上，你可以简单地理解为，kubectl replace 的执行过程，是使用新的 YAML 文件中的 API 对象，替换原有的 API 对象；而 kubectl apply，则是执行了一个对原有 API 对象的 PATCH 操作。

更进一步地，这意味着 kube-apiserver 在响应命令式请求（比如，kubectl replace）的时候，一次只能处理一个写请求，否则会有产生冲突的可能。而对于声明式请求（比如，kubectl apply），一次能处理多个写操作，并且具备 Merge 能力。

## 编写yaml技巧

查看官方文档，[https://kubernetes.io/docs/reference/kubernetes-api/](https://kubernetes.io/docs/reference/kubernetes-api/)

```shell
$ kubectl explain pod
```

使用kubectl 的两个特殊参数 `--dry-run=client` 和 `-o yaml`，前者是空运行，后者是生成 YAML 格式，结合起来使用就会让 kubectl 不会有实际的创建动作，而只生成 YAML 文件。

```shell
$ kubectl run ngx --image=nginx:alpine --dry-run=client -o yaml
$ kubectl create deployment ngx-dep --image=nginx:alpine --dry-run=client -o yaml
```

一般不直接创建Pod，而是创建Workload Reosurces，比如Deployment，这些里面包含PodTemplate

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: hello
spec:
  template:
    # This is the pod template
    spec:
      containers:
      - name: hello
        image: busybox:1.28
        command: ['sh', '-c', 'echo "Hello, Kubernetes!" && sleep 3600']
      restartPolicy: OnFailure
    # The pod template ends here
```

## kubectl command
```shell
$ kubectl get all -n example
$ kubectl get pods --selector=app=frontend -o jsonpath='{.items[*].spec.containers[0].image}'

$ kubectl logs busy-pod
$ kubectl get pods
$ kubectl describe pod busy-pod

$ echo 'aaa' > a.txt
$ kubectl cp a.txt ngx-pod:/tmp

$ kubectl exec -it ngx-pod -- sh

$ kubectl patch hpa backend -p '{"spec":{"minReplicas": 3}}' -n example
$ kubectl get replicaset --watch -n example
$ kubectl set image deployment/backend flask-backend=lyzhang1999/backend:v1 -n example
```

[kubectl-command](https://smoothies.com.cn/kubernetes-docs/%E7%BB%84%E4%BB%B6/Kubectl/kubectl-command.html)