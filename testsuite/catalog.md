# Test catalog

This file contains descriptions of the conformance tests per plugin.

## Arc for K8s Platform

This test plugin will determine if the Kubernetes cluster is Azure Arc conformant. Following tests are a part of this test suite:

- `test_identity_operator`: This test will look for the presence of secrets ‘azure-identity-certificate’ and 'config-agent-identity-request-token'. It will also watch the custom resource ‘config-agent-identity-request’ to check if it has been updated with token reference to the secret.

- `test_connected_cluster_metadata`: This test will watch the custom resource 'clustermetadata' to check if the custom resource status has been updated with cluster metadata properties. Then it will check if check if the metadata properties are present in the ARM resource.

- `test_metrics_and_logging`: This test will check the logs to ensure that metrics agent and fluent bit sidecar containers successfully pushed metrics and logs to data plane.

- `CSPScenarioTestAsync,HPScenarioTestAsync`: These tests will ensure that 'clusterconnect' scenarios work by making K8s calls to the connected cluster.
  
- `test_wif`: This test will ensure that the cluster can be onboarded as an Arc cluster with the Workload Identity Federation enabled, and the mutating webhook required for this feature is successfully installed. The test only runs if environment variable `TEST_WIF` is set to `true`  (please note that this feature does not work in an AKS and Openshift cluster).


## Arc Agent Cleanup

This test plugin runs a single test which is responsible for cleaning up the arc-agents.

- `test_arc_agent_cleanup`: This test will wait until all other arc plugins are in a terminal state and then proceed with the cleanup of azure-arc agents.


## Arc for Data services Conformance Tests (Indirectly Connected Mode)

This test plugin will determine if the Kubernetes cluster is conformant with Arc Data Services (Indirectly Connected Mode). 

Following tests are a part of this test suite:

- `test_check_namespace_existence`: This test will be responsible for monitoring the given namespace created or not. It will fail if the given namespace already found.

- `test_data_controller_ready`: This test will look for the presence of data controller and its status.

- `test_create_sql_mi`: This test will look for the presence of SQL managed instance and its status.

- `test_check_pod_existence`: This test will watch the pods created under the given namespace and its status(RUNNING).

- `test_check_pv_existence`: This test will watch the persistent volumes status and volume is bound to a claim.

- `test_ds_cleanup`: This test will cleanup all the data service resources under the given namespace.

- `test_create_postgressql`: This test will look for the presence of PostgreSQL server and its status.

- `test_scale_out_postgressql`: This test will look for PostgreSQL Hyperscale server was scaled out.

## Arc for Data services Conformance Tests (Directly Connected Mode)

This test plugin will determine if the Kubernetes cluster is conformant with Arc Data Services (Directly Connected Mode). 

Following tests are a part of this test suite:

- `test_check_namespace_existence`: This test will be responsible for monitoring the given namespace created or not. It will fail if the given namespace already found.

- `test_data_controller_ready`: This test will look for the presence of data controller and its status.

- `test_check_connected_cluster_arm`: This test will look for the connectivity status of created connected cluster from azure portal.

- `test_check_azure_arc_namespace_existence`: This test will look for the presence of azure-arc namespace.

- `test_check_datacontroller_arm`: This test will look for the provisioning state of created datacontroller from azure portal.

- `test_check_kubernetes_extension_arm`: This test will look for the install state of created connected cluster extension from azure portal.

- `test_check_customlocation_arm`: This test will look for the provisioning state of created custom location from azure portal.

- `test_check_pod_existence`: This test will watch the pods created under the given namespace and its status(RUNNING).

- `test_check_pv_existence`: This test will watch the persistent volumes status and volume is bound to a claim.

- `test_create_sql_mi`: This test will look for the presence of SQL managed instance and its status.

- `test_ds_direct_cleanup`: This test will cleanup all the data service resources from azure portal and also under the given namespace.

## Data services Cleanup

By deleting the repective namespace we can clean up the Data services.

kubectl delete namespace
