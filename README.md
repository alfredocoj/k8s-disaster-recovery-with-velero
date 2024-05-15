# k8s-disaster-recovery-with-velero

## Pre-requirements
### Install the CLI

**Option 1: MacOS - Homebrew**
On macOS, you can use Homebrew to install the velero client:

```
brew install velero
```

**Option 2: GitHub release**
1. Download the latest release’s tarball for your client platform.

2. Extract the tarball:
```
tar -xvf <RELEASE-TARBALL-NAME>.tar.gz
```
3. Move the extracted velero binary to somewhere in your $PATH (/usr/local/bin for most users).

**Option 3: Windows - Chocolatey**
On Windows, you can use Chocolatey to install the velero client:

```
choco install velero
```

### Install the Azure CLI on Linux

https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt

### Prepare Azure Storage Account

Follow this tutorial [Install Velero with Azure Blob Storage](Back up, restore workload clusters using Velero).

For turn it more simple, chose it a option 4, [that uses storage account access key] (https://github.com/vmware-tanzu/velero-plugin-for-microsoft-azure/blob/main/README.md#option-4-use-storage-account-access-key). See script `velero-prepare.sh`.

### Install vault and configure the vault agent sidecar.

Follow this documentation: https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-sidecar#install-the-vault-helm-chart.

*Obs.:* the `serviceAccount` of the velero is named `"velero"`.

## Install and configure the server components
There are two supported methods for installing the Velero server components:

- the `velero install` CLI command
- the [Helm chart](https://vmware-tanzu.github.io/helm-charts/) (the choise option for our tutorial).
- Create a secret with information about credentials to access the storage account:
```
kubectl create namespace velero
kubectl create secret generic credentials-velero --from-file=credentials-velero.txt -n velero
```
Obs.: This secret is not more necessary, because this current solution use a vault-agent sidecar to mount a /vault/secret/credentials-vault.txt. To create a vault service use this documetation availabel on https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-sidecar#install-the-vault-helm-chart.

## Intall velero on kubernetes via helm chart
```
helm template vmware-tanzu/velero --namespace velero -f values.yaml --generate-name

```


## Examples

After you set up the Velero server, you can clone the examples used in the following sections by running the following:

```
git clone https://github.com/vmware-tanzu/velero.git
cd velero
```

### Basic example (without PersistentVolumes)

1. Start the sample nginx app:

```
kubectl apply -f examples/nginx-app/base.yaml
```
2. Create a backup:

```
velero backup create nginx-backup --include-namespaces nginx-example

velero backup describe nginx-backup

```

3. Simulate a disaster:
```
kubectl delete namespaces nginx-example
```
Wait for the namespace to be deleted.

4. Restore your lost resources:

```
velero restore create --from-backup nginx-backup
```

### Snapshot example (with PersistentVolumes)
NOTE: For Azure, you must run Kubernetes version 1.7.2 or later to support PV snapshotting of managed disks.

1. Start the sample nginx app:
```
kubectl apply -f examples/nginx-app/with-pv.yaml
```

2. Create a backup with PV snapshotting. --csi-snapshot-timeout is used to setup time to wait before CSI snapshot creation timeout. The default value is 10 minutes:

```
velero backup create nginx-backup --include-namespaces nginx-example --csi-snapshot-timeout=20m
```

3. Simulate a disaster:
```
kubectl delete namespaces nginx-example
```
Because the default [reclaim policy](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reclaiming) for dynamically-provisioned PVs is “Delete”, these commands should trigger your cloud provider to delete the disk that backs the PV. Deletion is asynchronous, so this may take some time. Before continuing to the next step, check your cloud provider to confirm that the disk no longer exists.

4. Restore your lost resources:
```
velero restore create --from-backup nginx-backup
```

## Uninstalling Velero

If you would like to completely uninstall Velero from your cluster, the following commands will remove all resources created by velero install:

```
kubectl delete namespace/velero clusterrolebinding/velero
kubectl delete crds -l component=velero
```

## Reference

[VMware Tanzu Helm Repository](https://vmware-tanzu.github.io/helm-charts/)

[velero plugin for microsoft azure](https://github.com/vmware-tanzu/velero-plugin-for-microsoft-azure/blob/main/README.md)

[Backup Storage Location](https://github.com/vmware-tanzu/velero-plugin-for-microsoft-azure/blob/main/backupstoragelocation.md)
