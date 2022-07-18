# Set the following environment variables to run the test suite

# Common Variables
# Some of the variables need to be populated from the service principal and storage account details provided to you by Microsoft
$AZ_TENANT_ID="" # tenant field of the service principal
$AZ_SUBSCRIPTION_ID="" # subscription id of the azure subscription (will be provided)
$AZ_CLIENT_ID="" # appid field of the service principal
$AZ_CLIENT_SECRET="" # password field of the service principal
$AZ_STORAGE_ACCOUNT="" # name of your storage account
$AZ_STORAGE_ACCOUNT_SAS="`"<your-sas-token-here>`"" # sas token for your storage account, please add it within the quotes
$RESOURCE_GROUP="" # resource group name; set this to the resource group
$OFFERING_NAME="" # name of the partner offering; use this variable to distinguish between the results tar for different offerings
$LOCATION="eastus" # location of the arc connected cluster
$NAMESPACE="arc-ds-controller" # namespace of the data controller
$CONNECTIVITY_MODE="indirect" # choose connectivty mode for data services
$SERVICE_TYPE="NodePort" # Using a NodePort gives you the freedom to set up your own load-balancing solution or you can set LoadBalancer service type if your environment supports to generate external IPs.
$CONFIG_PROFILE="azure-arc-aks-default-storage" # choose the config profile
$DATA_CONTROLLER_STORAGE_CLASS="default" # choose the storage class for data controller
$SQL_MI_STORAGE_CLASS="default" # choose the storage class for sql mi
$PSQL_STORAGE_CLASS="default" # choose the storage class for postgreSQL
$AZDATA_USERNAME="azureuser" # database username
$AZDATA_PASSWORD="" # database password
$MEMORY="4Gi" # The request for the capacity of the managed instance as an integer number followed by Gi (gigabytes). Example: 4Gi or 8Gi
$SQL_INSTANCE_NAME="arc-sql" # sql instance name
$PSQL_SERVERGROUP_NAME="arc-psql" # postgreSQL server name
$INFRASTRUCTURE="azure" # Allowed values are alibaba, aws, azure, gpc, onpremises, other.
## For PRE-RELEASE test please uncomment and pass the required values for below parameters.
#$RELEASE_TYPE="PRE-RELEASE"
## Allowed repository names are arcdata/preview or arcdata/test
#$REPOSITORY="arcdata/test"
## Image Tag will be changed based on PRE-RELEASE versions
#$IMAGE_TAG="v1.9.0_2022-07-12"

# In case your cluster is behind an outbound proxy, please add the following environment variables in the below command
# --plugin-env azure-arc-ds-platform.HTTPS_PROXY="http://<proxy ip>:<proxy port>"
# --plugin-env azure-arc-ds-platform.HTTP_PROXY="http://<proxy ip>:<proxy port>"
# --plugin-env azure-arc-ds-platform.NO_PROXY="kubernetes.default.svc,<ip CIDR etc>"

# In case your outbound proxy is setup with certificate authentication, follow the below steps:
# Create a Kubernetes generic secret with the name sonobuoy-proxy-cert with key proxycert in any namespace:
# kubectl create secret generic sonobuoy-proxy-cert --from-file=proxycert=<path-to-cert-file>
# By default we check for the secret in the default namespace. In case you have created the secret in some other namespace, please add the following variables in the sonobuoy run command: 
# --plugin-env azure-arc-ds-platform.PROXY_CERT_NAMESPACE="<namespace of sonobuoy secret>"

#az login --service-principal --username $AZ_CLIENT_ID --password $AZ_CLIENT_SECRET --tenant $AZ_TENANT_ID
#az account set -s $AZ_SUBSCRIPTION_ID

Write-Host "Running the test suite for Azure Arc-enabled Data services for Indirect connect mode."

sonobuoy run --wait --config config.json `
--plugin arc-dataservices/dataservices.yaml `
--plugin-env azure-arc-ds-platform.NAMESPACE=$NAMESPACE `
--plugin-env azure-arc-ds-platform.CONFIG_PROFILE=$CONFIG_PROFILE `
--plugin-env azure-arc-ds-platform.DATA_CONTROLLER_STORAGE_CLASS=$DATA_CONTROLLER_STORAGE_CLASS `
--plugin-env azure-arc-ds-platform.CONNECTIVITY_MODE=$CONNECTIVITY_MODE `
--plugin-env azure-arc-ds-platform.SERVICE_TYPE=$SERVICE_TYPE `
--plugin-env azure-arc-ds-platform.SQL_MI_STORAGE_CLASS=$SQL_MI_STORAGE_CLASS `
--plugin-env azure-arc-ds-platform.PSQL_STORAGE_CLASS=$PSQL_STORAGE_CLASS `
--plugin-env azure-arc-ds-platform.AZDATA_USERNAME=$AZDATA_USERNAME `
--plugin-env azure-arc-ds-platform.AZDATA_PASSWORD=$AZDATA_PASSWORD `
--plugin-env azure-arc-ds-platform.MEMORY=$MEMORY `
--plugin-env azure-arc-ds-platform.SQL_INSTANCE_NAME=$SQL_INSTANCE_NAME `
--plugin-env azure-arc-ds-platform.PSQL_SERVERGROUP_NAME=$PSQL_SERVERGROUP_NAME `
--plugin-env azure-arc-ds-platform.TENANT_ID=$AZ_TENANT_ID `
--plugin-env azure-arc-ds-platform.SUBSCRIPTION_ID=$AZ_SUBSCRIPTION_ID `
--plugin-env azure-arc-ds-platform.RESOURCE_GROUP=$RESOURCE_GROUP `
--plugin-env azure-arc-ds-platform.LOCATION=$LOCATION `
--plugin-env azure-arc-ds-platform.CLIENT_ID=$AZ_CLIENT_ID `
--plugin-env azure-arc-ds-platform.CLIENT_SECRET=$AZ_CLIENT_SECRET `
--plugin-env azure-arc-ds-platform.INFRASTRUCTURE=$INFRASTRUCTURE `
--plugin-env azure-arc-ds-platform.RELEASE_TYPE=$RELEASE_TYPE `
--plugin-env azure-arc-ds-platform.REPOSITORY=$REPOSITORY `
--plugin-env azure-arc-ds-platform.IMAGE_TAG=$IMAGE_TAG


Write-Host "Test execution completed..Retrieving results"

$sonobuoyResults=$(sonobuoy retrieve)
sonobuoy results $sonobuoyResults
#mkdir results
New-Item -Path . -Name "results" -ItemType "directory"
#mv $sonobuoyResults results/$sonobuoyResults
Move-Item -Path $sonobuoyResults -Destination results\$sonobuoyResults
#cp partner-metadata.md results/partner-metadata.md
Copy-Item .\partner-metadata.md  -Destination results\partner-metadata.md
tar -czvf conformance-results.tar.gz results
#rm -rf results
Remove-Item .\results -Recurse
Write-Host "Publishing results.."

az login --service-principal --username $AZ_CLIENT_ID --password $AZ_CLIENT_SECRET --tenant $AZ_TENANT_ID
az account set -s $AZ_SUBSCRIPTION_ID

az storage container create -n conformance-results-ds --account-name $AZ_STORAGE_ACCOUNT --sas-token $AZ_STORAGE_ACCOUNT_SAS
az storage blob upload --file conformance-results.tar.gz --name conformance-results-$OFFERING_NAME.tar.gz --container-name conformance-results-ds --account-name $AZ_STORAGE_ACCOUNT --sas-token $AZ_STORAGE_ACCOUNT_SAS