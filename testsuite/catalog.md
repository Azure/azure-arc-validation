# Test catalog

This file contains descriptions of the conformance tests per plugin.

## Arc for K8s Platform

This test plugin will determine if the Kubernetes cluster is Azure Arc conformant. Following tests are a part of this test suite:

- `test_identity_operator`: This test will look for the presence of secrets ‘azure-identity-certificate’ and 'config-agent-identity-request-token'. It will also watch the custom resource ‘config-agent-identity-request’ to check if it has been updated with token reference to the secret.

- `test_connected_cluster_metadata`: This test will watch the custom resource 'clustermetadata' to check if the custom resource status has been updated with cluster metadata properties. Then it will check if check if the metadata properties are present in the ARM resource.

- `test_metrics_and_logging`: This test will check the logs to ensure that metrics agent and fluent bit sidecar containers successfully pushed metrics and logs to data plane.

- `test_kubernetes_configuration_helm_operator`: This test will ensure that a source control configuration is created on ARM and that the `complianceState` field reflects 'Installed'. Then it will check if the helm operator successfully deployed the resources.

- `test_kubernetes_configuration_flux_operator`: This test will ensure that a source control configuration is created on ARM and that the `complianceState` field reflects 'Installed'. Then it will check if the flux operator successfully deployed the resources.


## Arc Agent Cleanup

This test plugin runs a single test which is responsible for cleaning up the arc-agents.

- `test_arc_agent_cleanup`: This test will wait until all other arc plugins are in a terminal state and then proceed with the cleanup of azure-arc agents.


## Arc Data Services

This test plugin will determine if the Kubernetes cluster is Azure Arc data services conformant. Following tests are a part of this test suite:

- `test_check_namespace_existence`: This test will be responsible for monitoring the given namespace created or not. It will fail if the given namespace already found.

- `test_data_controller_ready`: This test will look for the presence of data controller and its status.

- `test_azdata_login`: This test will check for log in to the cluster's controller endpoint and set its namespace as your active context.

- `test_create_sql_mi`: This test will look for the presence of SQL managed instance and its status.

- `test_check_pod_existence`: This test will watch the pods created under the given namespace and its status(RUNNING).

- `test_check_pv_existence`: This test will watch the persistent volumes status and volume is bound to a claim.

- `test_ds_cleanup`: This test will cleanup all the data service resources under the given namespace.



