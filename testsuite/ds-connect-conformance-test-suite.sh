# Set the following environment variables to run the test suite

# Common Variables
# Some of the variables need to be populated from the service principal and storage account details provided to you by Microsoft
OBJECT_ID= # object id field of the service principal
CUSTOM_LOCATION_OID= # object id field of the service principal
AZ_TENANT_ID= # tenant field of the service principal
AZ_SUBSCRIPTION_ID= # subscription id of the azure subscription (will be provided)
AZ_CLIENT_ID= # appid field of the service principal
AZ_CLIENT_SECRET= # password field of the service principal
AZ_STORAGE_ACCOUNT= # name of your storage account
AZ_STORAGE_ACCOUNT_SAS="" # sas token for your storage account, please add it within the quotes
RESOURCE_GROUP= # resource group name; set this to the resource group
OFFERING_NAME= # name of the partner offering; use this variable to distinguish between the results tar for different offerings
LOCATION=eastus # location of the arc connected cluster
NAMESPACE=arc-ds-controller # namespace of the data controller
CLUSTERNAME=arc-ds-controller # name of the arc connected cluster
CONNECTIVITY_MODE=direct # choose connectivty mode for data services
CONFIG_PROFILE=azure-arc-aks-default-storage # choose the config profile
DATA_CONTROLLER_STORAGE_CLASS=default # choose the storage class for data controller
SQL_MI_STORAGE_CLASS=default # choose the storage class for sql mi
AZDATA_USERNAME=azureuser # database username
AZDATA_PASSWORD=Welcome1234% # database password
SQL_INSTANCE_NAME=arc-sql # sql instance name
INFRASTRUCTURE=azure # Allowed values are alibaba, aws, azure, gpc, onpremises, other.

# Platform Cleanup Plugin
CLEANUP_TIMEOUT=3600 # time in seconds after which the platform cleanup plugin times out

# In case your cluster is behind an outbound proxy, please add the following environment variables in the below command
# --plugin-env azure-arc-platform.HTTPS_PROXY="http://<proxy ip>:<proxy port>"
# --plugin-env azure-arc-platform.HTTP_PROXY="http://<proxy ip>:<proxy port>"
# --plugin-env azure-arc-platform.NO_PROXY="kubernetes.default.svc,<ip CIDR etc>"
# --plugin-env azure-arc-ds-connect-platform.HTTPS_PROXY="http://<proxy ip>:<proxy port>"
# --plugin-env azure-arc-ds-connect-platform.HTTP_PROXY="http://<proxy ip>:<proxy port>"
# --plugin-env azure-arc-ds-connect-platform.NO_PROXY="kubernetes.default.svc,<ip CIDR etc>"

# In case your outbound proxy is setup with certificate authentication, follow the below steps:
# Create a Kubernetes generic secret with the name sonobuoy-proxy-cert with key proxycert in any namespace:
# kubectl create secret generic sonobuoy-proxy-cert --from-file=proxycert=<path-to-cert-file>
# By default we check for the secret in the default namespace. In case you have created the secret in some other namespace, please add the following variables in the sonobuoy run command: 
# --plugin-env azure-arc-platform.PROXY_CERT_NAMESPACE="<namespace of sonobuoy secret>"
# --plugin-env azure-arc-ds-connect-platform.PROXY_CERT_NAMESPACE="<namespace of sonobuoy secret>"
# --plugin-env azure-arc-agent-cleanup.PROXY_CERT_NAMESPACE="namespace of sonobuoy secret"

echo "Running the test suite.."

sonobuoy run --wait --config src/plugins/common/config.json \
--plugin arc-k8s-platform/platform.yaml \
--plugin-env azure-arc-platform.TENANT_ID=$AZ_TENANT_ID \
--plugin-env azure-arc-platform.SUBSCRIPTION_ID=$AZ_SUBSCRIPTION_ID --plugin-env azure-arc-platform.RESOURCE_GROUP=$RESOURCE_GROUP \
--plugin-env azure-arc-platform.CLUSTER_NAME=$CLUSTERNAME --plugin-env azure-arc-platform.LOCATION=$LOCATION \
--plugin-env azure-arc-platform.CLIENT_ID=$AZ_CLIENT_ID --plugin-env azure-arc-platform.CLIENT_SECRET=$AZ_CLIENT_SECRET \
--plugin-env azure-arc-platform.OBJECT_ID=$OBJECT_ID --plugin-env azure-arc-platform.CUSTOM_LOCATION_OID=$CUSTOM_LOCATION_OID \
--plugin arc-dataservices/dataservices-connect.yaml \
--plugin-env azure-arc-ds-connect-platform.NAMESPACE=$NAMESPACE \
--plugin-env azure-arc-ds-connect-platform.CLUSTER_NAME=$CLUSTERNAME \
--plugin-env azure-arc-ds-connect-platform.CONNECTIVITY_MODE=$CONNECTIVITY_MODE \
--plugin-env azure-arc-ds-connect-platform.CONFIG_PROFILE=$CONFIG_PROFILE \
--plugin-env azure-arc-ds-connect-platform.DATA_CONTROLLER_STORAGE_CLASS=$DATA_CONTROLLER_STORAGE_CLASS \
--plugin-env azure-arc-ds-connect-platform.SQL_MI_STORAGE_CLASS=$SQL_MI_STORAGE_CLASS \
--plugin-env azure-arc-ds-connect-platform.AZDATA_USERNAME=$AZDATA_USERNAME \
--plugin-env azure-arc-ds-connect-platform.AZDATA_PASSWORD=$AZDATA_PASSWORD \
--plugin-env azure-arc-ds-connect-platform.TENANT_ID=$AZ_TENANT_ID \
--plugin-env azure-arc-ds-connect-platform.SUBSCRIPTION_ID=$AZ_SUBSCRIPTION_ID \
--plugin-env azure-arc-ds-connect-platform.RESOURCE_GROUP=$RESOURCE_GROUP \
--plugin-env azure-arc-ds-connect-platform.SQL_INSTANCE_NAME=$SQL_INSTANCE_NAME \
--plugin-env azure-arc-ds-connect-platform.LOCATION=$LOCATION \
--plugin-env azure-arc-ds-connect-platform.CLIENT_ID=$AZ_CLIENT_ID \
--plugin-env azure-arc-ds-connect-platform.CLIENT_SECRET=$AZ_CLIENT_SECRET \
--plugin-env azure-arc-ds-connect-platform.INFRASTRUCTURE=$INFRASTRUCTURE \
--plugin arc-k8s-platform/cleanup.yaml \
--plugin-env azure-arc-agent-cleanup.TENANT_ID=$AZ_TENANT_ID \
--plugin-env azure-arc-agent-cleanup.SUBSCRIPTION_ID=$AZ_SUBSCRIPTION_ID --plugin-env azure-arc-agent-cleanup.RESOURCE_GROUP=$RESOURCE_GROUP \
--plugin-env azure-arc-agent-cleanup.CLUSTER_NAME=$CLUSTERNAME --plugin-env azure-arc-agent-cleanup.CLEANUP_TIMEOUT=$CLEANUP_TIMEOUT \
--plugin-env azure-arc-agent-cleanup.CLIENT_ID=$AZ_CLIENT_ID --plugin-env azure-arc-agent-cleanup.CLIENT_SECRET=$AZ_CLIENT_SECRET

echo "Test execution completed..Retrieving results"

sonobuoyResults=$(sonobuoy retrieve)
sonobuoy results $sonobuoyResults
mkdir results
mv $sonobuoyResults results/$sonobuoyResults
cp partner-metadata.md results/partner-metadata.md
tar -czvf conformance-results.tar.gz results
rm -rf results

echo "Publishing results.."

az login --service-principal --username $AZ_CLIENT_ID --password $AZ_CLIENT_SECRET --tenant $AZ_TENANT_ID
az account set -s $AZ_SUBSCRIPTION_ID

az storage container create -n conformance-results-ds-connect --account-name $AZ_STORAGE_ACCOUNT --sas-token $AZ_STORAGE_ACCOUNT_SAS
az storage blob upload --file conformance-results.tar.gz --name conformance-results-$OFFERING_NAME.tar.gz --container-name conformance-results-ds-connect --account-name $AZ_STORAGE_ACCOUNT --sas-token $AZ_STORAGE_ACCOUNT_SAS
