# Running the Conformance Test Suite

This document will enumerate everything you need to do run the sonobuoy based conformance test suite on your environment. The test catalog can be found [here](catalog.md).

## Prerequisites

1. Install [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl).
1. Set the `KUBECONFIG` environment variable to the path to your kubeconfig file of your cluster.
2. Install [sonobuoy](https://github.com/vmware-tanzu/sonobuoy#installation). Run `sonobuoy version` to verify it's installed correctly.
3. Address the [network requirements](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/quickstart-connect-cluster#meet-network-requirements) on your cluster for the Arc agents to communicate with Azure.
4. Download and install [git](https://git-scm.com/downloads).
5. Download and install [az cli](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).

### Additional Prerequisites for Arc enabled Data Services

1. Install [Azure Data CLI](https://docs.microsoft.com/en-us/sql/azdata/install/deploy-install-azdata?view=sql-server-ver15).

## Running the script and publishing the results

1. Clone this repository.
2. Edit the [`partner-metadata.md`](partner-metadata.md) file and fill in the required details.

### Arc for K8s
1. Edit the [`k8s-conformance-test-suite.sh`](k8s-conformance-test-suite.sh) file and set the values for the required environment variables.
2. If your cluster is behind an outbound proxy, please edit the above file according to the instruction provided as comments for proxy configuration.
3. Make the test suite file executable by running `chmod +x k8s-conformance-test-suite.sh`.
4. Execute the script by running `./k8s-conformance-test-suite.sh`.
5. The test suite will take the storage account details as environment variables and will handle publishing the results in the right format.

### Arc enabled Data Services
1. Edit the [`ds-conformance-test-suite.sh`](ds-conformance-test-suite.sh) file and set the values for the required environment variables.
2. If you wish to bring your own custom control deployment profile with your own configuration, please follow the below process to provide the control.json to sonobuoy plugin:
```
kubectl create ns arc-ds-config ; kubectl -n arc-ds-config create configmap arc-ds-config --from-file=/opt/azdata/lib/python3.6/site-packages/azdata/cli/commands/arc/deployment-configs/azure-arc-aks-default-storage/control.json
```
Please update the `CONFIG_PROFILE` variable in the above script accordingly.

3. Make the test suite file executable by running `chmod +x ds-conformance-test-suite.sh`.
4. Execute the script by running `./ds-conformance-test-suite.sh`.
5. The test suite will take the storage account details as environment variables and will handle publishing the results in the right format.

## Retrieving the results

1. Once the above script executes successfully, you can run `sonobuoy retrieve` to get the tar file with the test results and logs.
2. Run `sonobuoy results <path_to_tar>` to display the results. The results are displayed per sonobuoy plugin.
3. To take a deeper look at the test logs:
    1. Extract the tar file by running `tar -xvzf <path_to_tar>`
    2. You will find the pod logs in the `podlogs` folder and the test logs for each test per plugin in the `plugins` folder.

## Cleaning up the test cluster

Sonobuoy creates a few resources (a namespace and some cluster scoped resources) which remain in the cluster unless explicitly cleaned.

Run `sonobuoy delete --wait` to cleanup all sonobuoy resources. This step is important as failing to do so will prevent you from running sonobuoy tests again on the cluster. If you are running the tests for both K8s and Data Services on the same cluster, please run this command in between the two test runs.