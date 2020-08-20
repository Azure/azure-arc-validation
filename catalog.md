# Test catalog

This file contains descriptions of the conformance test plugins present in this repository.

## Core

This test plugin will determine if the Kubernetes cluster is Azure Arc conformant. Following tests are a part of this test suite:

- `test_connected_cluster_resource`: This test will be responsible for monitoring the connected cluster ARM resource. It will fail if the connected cluster was not found or did not have provisioning state as 'Succeeded'.

- `test_identity_operator`: This test will look for the presence of secrets ‘azure-identity-certificate’ and 'config-agent-identity-request-token'. It will also watch the custom resource ‘config-agent-identity-request’ to check if it has been updated with token reference to the secret.

- `test_connected_cluster_metadata`: This test will watch the custom resource 'clustermetadata' to check if the custom resource status has been updated with cluster metadata properties. Then it will check if check if the metadata properties are present in the ARM resource.

- `test_metrics_and_logging`: This test will check the logs to ensure that metrics agent and fluent bit sidecar containers successfully pushed metrics and logs to data plane.

- `test_kubernetes_configuration_helm_operator`: This test will ensure that a source control configuration is created on ARM and that the `complianceState` field reflects 'Installed'. Then it will check if the helm operator successfully deployed the resources.

- `test_kubernetes_configuration_flux_operator`: This test will ensure that a source control configuration is created on ARM and that the `complianceState` field reflects 'Installed'. Then it will check if the flux operator successfully deployed the resources.
