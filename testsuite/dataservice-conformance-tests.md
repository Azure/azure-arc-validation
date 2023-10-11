### Running the Arc enabled Data Services tests (Direct Mode) &#42;&#42;(Deprecated)&#42;&#42;


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

### Running the Arc enabled Data Services Tests (Indirect Mode) &#42;&#42;(Deprecated)&#42;&#42;


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

<br/>