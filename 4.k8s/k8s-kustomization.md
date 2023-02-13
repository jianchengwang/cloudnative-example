Kustomize is a standalone tool to customize Kubernetes objects through a [kustomization](https://kubectl.docs.kubernetes.io/references/kustomize/glossary/#kustomization) file.

Since 1.14, Kubectl also supports the management of Kubernetes objects using a kustomization file. To view Resources found in a directory containing a kustomization file, run the following command:

```shell
$ kubectl kustomize <kustomization_directory>
$ kubectl apply -k <kustomization_directory>
```

参考 [manage-kubernetes-objects/kustomization](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization)

## Generating Resources

ConfigMaps and Secrets hold configuration or sensitive data that are used by other Kubernetes objects, such as Pods. The source of truth of ConfigMaps or Secrets are usually external to a cluster, such as a .properties file or an SSH keyfile. Kustomize has secretGenerator and configMapGenerator, which generate Secret and ConfigMap from files or literals

## Setting cross-cutting fields

t is quite common to set cross-cutting fields for all Kubernetes resources in a project. Some use cases for setting cross-cutting fields:
1. setting the same namespace for all Resources
2. adding the same name prefix or suffix
3. adding the same set of labels
4. adding the same set of annotations

## Composing and Customizing Resources

It is common to compose a set of Resources in a project and manage them inside the same file or directory. Kustomize offers composing Resources from different files and applying patches or other customization to them.

## Bases and Overlays

Kustomize has the concepts of bases and overlays. A base is a directory with a kustomization.yaml, which contains a set of resources and associated customization. A base could be either a local directory or a directory from a remote repo, as long as a kustomization.yaml is present inside. An overlay is a directory with a kustomization.yaml that refers to other kustomization directories as its bases. A base has no knowledge of an overlay and can be used in multiple overlays. An overlay may have multiple bases and it composes all resources from bases and may also have customization on top of them.