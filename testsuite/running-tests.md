# Running the Conformance Test Suite

This document will enumerate everything you need to do run the sonobuoy based conformance test suite on your environment. The test catalog can be found [here](catalog.md).

## Prerequisites

1. Install [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl).
2. Set the `KUBECONFIG` environment variable to the path to your kubeconfig file of your cluster.
3. Address the [network requirements](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/quickstart-connect-cluster#meet-network-requirements) on your cluster for the Arc agents to communicate with Azure.


## Running the script and publishing the results

1. Clone three files azure-arc-conformance.properties, launch.yaml and kustomization.yaml.
2. Create a directory i.e., conformanceTest and move azure-arc-conformance.properties, launch.yaml and kustomization.yaml to the directory
3. Edit the azure-arc-conformance.properties file for enabling test plugins.
4. `cd conformanceTest`
5. Run command `kubectl apply -k .` Now tests should automatically start running.


### Watching kubernetes pod for current running status
1. `kubectl get pods -n azure-arc-kubernetes-conformance -w` It Should be in running state in 5 to 10 mins depending on the internet connection as it has to pull the images
2. Check logs of kubernetes pods `kubectl logs <pod_name> -n azure-arc-kubernetes-conformance --follow` This will show you current progress of the test, warnings and errors if any

## Retrieving the results

1. Once the above kubernetes job executes successfully, you will find the sonobuoy results tar file uploaded to the storage account configured in the property file.
2. Get result from kubernetes pod if result upload to storage account fails `kubectl cp azure-arc-kubernetes-conformance/<pod-name>:/<result-tar-file> /tmp/bar`
3. To take a deeper look at the test logs:
    1. Extract the tar file by running `tar -xvzf <path_to_tar>`
    2. You will find the pod logs in the `podlogs` folder and the test logs for each test per plugin in the `plugins` folder.

## Cleaning up the test cluster

Kubernetes job creates a few resources (a namespace and some cluster scoped resources) which remain in the cluster unless explicitly cleaned.

Run  `kubectl delete -k .` to cleanup all resources. This step is important as failing to do so will prevent you from running the conformance tests again on the cluster.
