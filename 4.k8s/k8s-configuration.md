## Env

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  ......
spec:
  replicas: 1
  ......
    spec:
      containers:
      - name: flask-backend
        image: lyzhang1999/backend:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 5000
        env:
        - name: DATABASE_URI
          value: pg-service
        - name: DATABASE_USERNAME
          value: postgres
        - name: DATABASE_PASSWORD
          value: postgres
```

```shell
$ kubectl exec -it $(kubectl get pods --selector=app=backend -n example -o jsonpath="{.items[0].metadata.name}") -n example -- sh
# env | grep DATABASE
DATABASE_URI=pg-service
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=postgres
```

```python
import os
db_uri = os.environ.get('DATABASE_URI')
```

## ConfigMap

[查看更多](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-pod-configmap)

ConfigMap是一个API对象，允许您存储配置以供其他对象使用。与大多数有规范的Kubernetes对象不同，ConfigMap有data和binaryData字段。这些字段接受键值对作为它们的值。data字段和binaryData都是可选的。data字段被设计为包含UTF-8字符串，而binaryData字段被设计为包含base64编码字符串的二进制数据。

您可以编写一个引用ConfigMap的Pod规范，并根据ConfigMap中的数据配置Pod中的容器。Pod和ConfigMap必须在同一个命名空间中。

ConfigMap 和 Secret 对存储数据的大小是有限制的，限制为 1MiB，官方文档：https://kubernetes.io/zh-cn/docs/concepts/configuration/configmap/#motivation

只有通过目录挂载的configmap才具备热更新能力，其余通过环境变量，通过subPath挂载的文件都不能动态更新。 并且有一个延迟。一般就是kubelet的定时更新频率

### 创建生成

```shell
# --from-file
$ kubectl create configmap game-config --from-file=configuration/configmap/
$ kubectl get configmaps game-config -o yaml
$ kubectl create configmap game-config-3 --from-file=game-special-key=configuration/configmap/game.properties
$ kubectl create configmap application-config --from-file=configuration/configmap/application.yaml

# --from-env-file
$ kubectl create configmap game-config-env-file \
       --from-env-file=configuration/configmap/game-env-file.properties

# --from-literal
$ kubectl create configmap special-config --from-literal=special.how=very --from-literal=special.type=charm

# configfile
$ kubectl apply -f configmap-multikeys.yaml -ne example
```

### Pod里使用

自行参考

[configuration/pod-configmap-env-var-valueFrom.yaml]

![configmap-keyRef](./configmap-keyRef.webp)

[configuration/pod-configmap-volume.yaml]

![configmap-volume](./configmap-volume.webp)

在一般情况下，使用 configmap 挂载文件时，会先覆盖掉挂载目录，然后再将 congfigmap 中的内容作为文件挂载进行。如果不想对原来的文件夹下的文件造成覆盖，只是将 configmap 中的每个 key，按照文件的方式挂载到目录下，可以使用 `mountPath + subpath` 参数。

```yaml
spec:
  template:
    spec:
      volumes:
        - name: conf
          configMap:
            name: spring-boot-demo-configmap  # 指定要使用的configmap名称
      containers:
        - name: spring-boot-demo-app
          volumeMounts:
            - name: conf   # 与上面的volumes.name保持一致
              mountPath: /spring-boot-demo/conf/application-test.yml
              subPath: application-test.yml
              readOnly: true
```

## Secret

参照ConfigMap，Secret 的加密能力相对薄弱，它是以 Base64 来加密内容的，在实际的业务中使用场景也比较有限。

在将 Secret 挂载为文件时，Kubernetes 自动将 Secret 进行了 Base64 解码操作，这种方式和使用 ConfigMap 挂载文件的效果是一样的。

```shell
echo -n "123456" | base64
MTIzNDU2
```

## 其他

如果需要统一的配置中心，也可以选用 [nacos](https://github.com/alibaba/nacos) 或者 [apollo](https://github.com/apolloconfig/apollo/)