# Running the Conformance Test Suite

This document will enumerate everything you need to do run the sonobuoy based conformance test suite on your environment. The test catalog can be found [here](catalog.md).


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

### Cleaning up the test cluster

1. Kubernetes job creates a few resources (a namespace and some cluster scoped resources) which remain in the cluster unless explicitly cleaned.
2. Run  `kubectl delete -k .` to cleanup all resources. This step is important as failing to do so will prevent you from running the conformance tests again on the cluster.

<br/>

## Running the Arc enabled Data Services tests with CI-Launcher


This document will enumerate everything you need to do to run the automated CI-Launcher that perform end-to-end tests on your environment. The Automated validation testing catalog can be found [here](https://learn.microsoft.com/en-us/azure/azure-arc/data/automated-integration-testing).
<br/>

### Prerequisites

Please follow the [link](https://learn.microsoft.com/en-us/azure/azure-arc/data/automated-integration-testing#prerequisites) to fulfill the prerequisites. As part of Conformance test we share basic credentials.
To consist of Log Analytics workspace, please create WORKSPACE_ID and WORKSPACE_SHARED_KEY by using below commands.
```
az login --service-principal -u ${CLIENT_ID} -p ${CLIENT_SECRET} --tenant ${TENANT_ID}
```
Linux(Bash)
```
WORKSPACE_ID=$(az monitor log-analytics workspace create -g $RESOURCE_GROUP -n $partnername-analytics -l $location | jq .customerId | xargs)
echo $WORKSPACE_ID
WORKSPACE_SHARED_KEY=$(az monitor log-analytics workspace get-shared-keys --resource-group $RESOURCE_GROUP --workspace-name $partnername-analytics | jq .primarySharedKey | xargs)
echo $WORKSPACE_SHARED_KEY
```
Windows(PowerShell)
```
$WORKSPACE_ID=$(az monitor log-analytics workspace create -g $RESOURCE_GROUP_NAME -n $partnername_loganalytics -l $LOCATION)
$WORKSPACE_ID=$WORKSPACE_ID | Select-String "customerId"
$WORKSPACE_ID=$WORKSPACE_ID -split(":") | Select-String "customerId" -notMatch
$WORKSPACE_ID=$WORKSPACE_ID -split(",")
$WORKSPACE_ID=$WORKSPACE_ID.Replace("`"","")
echo $WORKSPACE_ID

$WORKSPACE_SHARED_KEY=$(az monitor log-analytics workspace get-shared-keys --resource-group $RESOURCE_GROUP_NAME --workspace-name $partnername_loganalytics | Select-String "primarySharedKey") -split(":") | Select-String "primarySharedKey" -notMatch
$WORKSPACE_SHARED_KEY=$WORKSPACE_SHARED_KEY -split(",")
$WORKSPACE_SHARED_KEY=$WORKSPACE_SHARED_KEY.Replace("`"","")
echo $WORKSPACE_SHARED_KEY
```
### Partner metadata preparation

Please add and update the following variables with the required partner environment details in the `.test.env` file.
```
# The partner's solution name and version should be provided in this variable to distinguish between results for different solution names and versions.
export SOLUTIONNAME_VERSION="TKG-2.1.0"
export UPSTREAM_KUBERNETES_VERSION="TKG 2.1.0"
export KUBERNETES_DISTRIBUTION_VERSION="v1.7.2_vmware.1"
# Additional Storage/Network Driver details (if applicable)
export STORAGE_NETWORK="Antrea v1.7.2_vmware.1"
# Private Cloud details (if applicable)
export PRIVATE_CLOUD="vSphere 7.0"
# Bare-metal Node details (if applicable)
export BARE_METAL_NODE=""
# OEM/IHV solution details (if applicable)
export OEM_IHV=""
```
To fine-tune SQL MI resources, please add and update the following variables with the required SQL MI constraints in the .test.env file.

```
export SQLMI_GP_CORES_REQUEST=1
export SQLMI_GP_CORES_LIMIT=1
export SQLMI_BC_CORES_REQUEST=3
export SQLMI_BC_CORES_LIMIT=4
export SQLMI_MEMORY_REQUEST=3Gi
export SQLMI_MEMORY_LIMIT=3Gi
```
### Kubernetes manifest preparation

Follow the [link](https://learn.microsoft.com/en-us/azure/azure-arc/data/automated-integration-testing#kubernetes-manifest-preparation) and update the variables based on your environment at .test.env and patch.json files. Please consider overlay AKS as default overlay or you can copy and create new overlay based on your environment. This test suite supports both Direct mode and Indirect mode.

Example
```
cp -r aks aks-hci
```

### Running the tests

Follow the [link](https://learn.microsoft.com/en-us/azure/azure-arc/data/automated-integration-testing#kubectl-apply) to deploy the launcher and tail the logs.
By default lancher will create data services with LoadBalancer serviceType. If we want to have serviceType as NodePort please add this below content at patch.json file.

```
,
{
    "op": "replace",
    "path": "spec.services/0/serviceType",
    "value": "NodePort"
}
```
If you wish to allocate additional CPU and memory for Controldb during Data Controller creation, please include the following snippet in `patch.json`.

```
        {
            "op": "add",
            "path": "spec.resources",
            "value": {
                    "controllerDb": {
                    "requests": {
                        "cpu": "200m",
                        "memory": "6Gi"
                    },
                    "limits": {
                        "cpu": "800m",
                        "memory": "6Gi"
                    }
                }
            }
        },
```

### Recommended Tests for Partner Scope
The following tests are recommended for the partner scope, and detailed information for each test suite will be available [here](https://learn.microsoft.com/en-us/azure/azure-arc/data/automated-integration-testing#tests-performed-per-test-suite).

&#42;&#42; NOTE: Make sure test suite names are seperated by space only. &#42;&#42;

| Modes  | Required test suite names | Optional test suite names  |
|-----------|-----------|-----------|
| Indirect | billing controldb nonroot sqlinstance | kube-rbac (Recommend to test against different K8s distros) 
ci-billing telemetry-grafana telemetry-kafka telemetry-monitorstack ci-sqlinstance sqlinstance-credentialrotation sqlinstance-ha sqlinstance-tde postgres|
| Direct | direct-crud direct-hydration controldb nonroot sqlinstance | ci-billing telemetry-grafana telemetry-kafka telemetry-monitorstack ci-sqlinstance sqlinstance-credentialrotation sqlinstance-ha sqlinstance-tde postgres |

### Examining Test Results
Follow the [link](https://learn.microsoft.com/en-us/azure/azure-arc/data/automated-integration-testing#examining-test-results) to view the logs from storage container.

### Cleaning up the test environment
Follow the [link](https://learn.microsoft.com/en-us/azure/azure-arc/data/automated-integration-testing#clean-up-resources) to delete the launcher run.<br/>


### Running the Arc enabled Data Services tests &#42;&#42;([Deprecated](dataservice-conformance-tests.md))&#42;&#42;