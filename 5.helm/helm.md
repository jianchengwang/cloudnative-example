[Helm](https://helm.sh/) 是一种真正意义上的 Kubernetes 应用的包管理工具，它对最终用户屏蔽了 Kubernetes 对象概念，将复杂度左移到了应用开发者侧，终端用户只需要提供安装参数，就可以将应用安装到 Kubernetes 集群内。

## install

安装helm，可以参考 [官方文档](https://helm.sh/docs/intro/install/)

```shell
$ curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

安装好 Helm 之后，在正式使用之前，你还要确保本地 Kubectl 和集群的连通性，Helm 和 Kubectl 默认读取的 Kubeconfig 文件路径都是 ~/.kube/config。

## Helm Chart 和 values.yaml

Chart 是 Helm 的一种应用封装格式，它由一些特定文件和目录组成。为了方便 Helm Chart 存储、分发和下载，它采用 tgz 的格式对文件和目录进行打包。

```shell
$ ls
Chart.yaml  templates   values.yaml
```

1. Chart.yaml 文件是 Helm Chart 的描述文件，例如名称、描述和版本等。
2. templates 目录用来存放模板文件，你可以把它视作 Kubernetes Manifest，但它和 Manifest 最大的区别是，模板文件可以包含变量，变量的值则来自于 values.yaml 文件定义的内容。
3. values.yaml 文件是安装参数定义文件，它不是必需的。

在 Helm Chart 被打包成 tgz 包时，如果 templates 目录下的 Kubernetes Manifest 包含变量，那么你需要通过它来提供默认的安装参数。作为最终用户，当安装某一个 Helm Chart 的时候，也可以提供额外的 YAML 文件来覆盖默认值。比如在上面的期望效果图中，我们为同一个 Helm Chart 提供不同的安装参数，就可以得到具有配置差异的多套环境。

## Helm Release

Helm Release 实际上是一个“安装”阶段的概念，它指的是本次安装的唯一标识（名称）。我们知道 Helm Chart 实际上是一个应用安装包，只有在安装（实例化）它时才会生效。它可以在同一个集群中甚至是同一个命名空间下安装多次，所以我们就需要为每次安装都起一个唯一的名字，这就是 Helm Release Name。

## 发布

要将 Helm Chart 推送到 GitHub Package，首先我们需要创建一个具备推送权限的 Token，你可以在这个 [链接](https://github.com/settings/tokens/new) 创建，并勾选 write:packages 权限。

```shell
$ helm registry login -u jianchengwang https://ghcr.io
```

请注意，由于 GitHub Package 使用的是 OCI 标准的存储格式，如果你使用的 helm 版本小于 3.8.0，则需要在运行这条命令之前增加 HELM_EXPERIMENTAL_OCI=1 的环境变量启用实验性功能。

然后，返回到示例应用的根目录下，执行 helm package 命令来打包 Helm Chart。

```shell
# 打包
$ helm package ./
# 推送到远端仓库
$ helm push kubernetes-example-0.1.0.tgz oci://ghcr.io/jianchengwang/helm
# 安装远端仓库的helm chart
$ helm install my-kubernetes-example oci://ghcr.io/jianchengwang/helm/kubernetes-example --version 0.1.0 --namespace remote-helm-staging --create-namespace --set frontend.autoscaling.averageUtilization=60 --set backend.autoscaling.averageUtilization=60
```

## 常用命令

```shell
# 调试模板
helm template ./ -f ./values-prod.yaml
# 查看已安装chart版本
helm list -A
# 更新升级，Helm 会自动对比新老版本之间的 Manifest 差异，并执行升级。
helm upgrade my-kubernetes-example ./ -n example
# 历史版本
helm history my-kuebrnetes-example -n example
# 回滚
$ helm rollback my-kubernetes-example 1 -n example
# 卸载
helm uninstall my-kubernetes-example -n example
```