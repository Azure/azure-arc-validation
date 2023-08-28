# Running the Conformance Test Suite

This document will enumerate everything you need to do run the sonobuoy based conformance test suite on your environment. The test catalog can be found [here](catalog.md).

<br/>

## Running the Arc enabled Kubernetes Tests

### Prerequisites

1. Install [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl).
2. Set the `KUBECONFIG` environment variable to the path to your kubeconfig file of your cluster.
3. Address the [network requirements](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/quickstart-connect-cluster#meet-network-requirements) on your cluster for the Arc agents to communicate with Azure.
4. Download and install [git](https://git-scm.com/downloads).

### Running the tests

1. Clone this repository.
2. Navigate to the testsuite directory from the repo root: `cd testsuite`.
3. Edit the [`partner-metadata.md`](partner-metadata.md) file and fill in the required details. For reference, please see the [`partner-metadata-sample.md`](partner-metadata-sample.md) file. 
4. Edit the [`azure-arc-conformance.properties`](azure-arc-conformance.properties) file and fill in the required environment variables. You will be provided the credentials to do so.
5. Run the command as follows: `kubectl apply -k .`
6. The test suite will take care of publishing the results to the storage account.

### Running the Arc enabled Data Services (Direct Mode) tests

1. By default, the test suite will run only the Arc enabled Kubernetes tests.
2. To run the data services tests in [direct mode](), set the `azure-arc-ds-connect-platform.enable` parameter to true and `azure-arc-ds-connect-platform.CONNECTIVITY_MODE` to direct in the `azure-arc-conformance.properties` file.
3. You can leverage the `PRE-RELEASE` feature to test pre-released versions of Azure Arc-enabled Data Services, which are made available on a predictable schedule. Please refer to this for [more](https://docs.microsoft.com/en-us/azure/azure-arc/data/preview-testing) details.

4. Fill out the additional parameters in the properties file.

### Monitoring the test progress

1. To get the test suite pod, run `kubectl get pods -n azure-arc-kubernetes-conformance -w`. The pod should reach running state in 5 to 10 minutes.
2. Get the pods logs by running `kubectl logs <pod_name> -n azure-arc-kubernetes-conformance --follow`. This will show you the current progress of the test, warnings and errors if any.

### Retrieving the results

1. The results for each run - N, N-1 and N-2 can be retrieved.
2. Retrieve the results from the kubernetes pod by running: `kubectl cp azure-arc-kubernetes-conformance/<pod-name>:<result-tar-file> results.tar.gz`
    1. To get the pod name use `kubectl get pods -n azure-arc-kubernetes-conformance`
    2. To get the result-tar-file name, exec into the pod `kubectl exec -it <pod-name> -n azure-arc-kubernetes-conformance -- bash`. The format will be "conformance-results-*.tar.gz".
    3. The result-tar-file will be present at root directory
3. To take a deeper look at the test logs:
    1. Extract the tar file by running `tar -xvzf <path_to_tar>`
    2. You will find the pod logs in the `podlogs` folder and the test logs for each test per plugin in the `plugins` folder.

### Cleaning up the test cluster

1. Kubernetes job creates a few resources (a namespace and some cluster scoped resources) which remain in the cluster unless explicitly cleaned.
2. Run  `kubectl delete -k .` to cleanup all resources. This step is important as failing to do so will prevent you from running the conformance tests again on the cluster.

<br/>

## Running the Arc enabled Data Services Tests (Indirect Mode)
1. By default, the test suite will run only the Arc enabled Kubernetes tests.
2. To run the data services tests in [indirect mode](), set the `azure-arc-ds-connect-platform.enable` parameter to true and `azure-arc-ds-connect-platform.CONNECTIVITY_MODE` to indirect in the `azure-arc-conformance.properties` file.
3. You can leverage the `PRE-RELEASE` feature to test pre-released versions of Azure Arc-enabled Data Services, which are made available on a predictable schedule. Please refer to this for [more](https://docs.microsoft.com/en-us/azure/azure-arc/data/preview-testing) details.

4. Fill out the additional parameters in the properties file.

### Monitoring the test progress

1. To get the test suite pod, run `kubectl get pods -n azure-arc-kubernetes-conformance -w`. The pod should reach running state in 5 to 10 minutes.
2. Get the pods logs by running `kubectl logs <pod_name> -n azure-arc-kubernetes-conformance --follow`. This will show you the current progress of the test, warnings and errors if any.

### Retrieving the results

1. The results for each run - N, N-1 and N-2 can be retrieved.
2. Retrieve the results from the kubernetes pod by running: `kubectl cp azure-arc-kubernetes-conformance/<pod-name>:<result-tar-file> results.tar.gz`
    1. To get the pod name use `kubectl get pods -n azure-arc-kubernetes-conformance`
    2. To get the result-tar-file name, exec into the pod `kubectl exec -it <pod-name> -n azure-arc-kubernetes-conformance -- bash`. The format will be "conformance-results-*.tar.gz".
    3. The result-tar-file will be present at root directory
3. To take a deeper look at the test logs:
    1. Extract the tar file by running `tar -xvzf <path_to_tar>`
    2. You will find the pod logs in the `podlogs` folder and the test logs for each test per plugin in the `plugins` folder.

### Cleaning up the test cluster

1. Kubernetes job creates a few resources (a namespace and some cluster scoped resources) which remain in the cluster unless explicitly cleaned.
2. Run  `kubectl delete -k .` to cleanup all resources. This step is important as failing to do so will prevent you from running the conformance tests again on the cluster.


