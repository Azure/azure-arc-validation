# Set the following environment variables to run the test suite

# Common Variables
# Some of the variables need to be populated from the service principal and storage account details provided to you by Microsoft
AZ_TENANT_ID= # tenant field of the service principal
AZ_SUBSCRIPTION_ID= # subscription id of the azure subscription (will be provided)
AZ_CLIENT_ID= # appid field of the service principal
AZ_CLIENT_SECRET= # password field of the service principal
AZ_STORAGE_ACCOUNT= # name of your storage account
AZ_STORAGE_ACCOUNT_SAS="" # sas token for your storage account, please add it within the quotes
RESOURCE_GROUP= # resource group name; set this to the resource group
LOCATION=eastus # location of the arc connected cluster
NAMESPACE=arc-ds-controller # namespace of the data controller
STORAGE_CLASS=default # choose the storage class
CONFIG_PROFILE=azure-arc-aks-default-storage # choose the config profile
AZDATA_USERNAME=azureuser # database username
AZDATA_PASSWORD=Welcome1234% # database password
SQL_INSTANCE_NAME=arc-sql # sql instance name

echo "Running the test suite.."

sonobuoy run --wait 
--plugin arc-dataservices/dataservices.yaml \
--plugin-env azure-arc-ds-platform.NAMESPACE=$NAMESPACE \
--plugin-env azure-arc-ds-platform.STORAGE_CLASS=$STORAGE_CLASS \
--plugin-env azure-arc-ds-platform.CONFIG_PROFILE=$CONFIG_PROFILE \
--plugin-env azure-arc-ds-platform.AZDATA_USERNAME=$AZDATA_USERNAME \
--plugin-env azure-arc-ds-platform.AZDATA_PASSWORD=$AZDATA_PASSWORD \
--plugin-env azure-arc-ds-platform.SQL_INSTANCE_NAME=$SQL_INSTANCE_NAME \
--plugin-env azure-arc-ds-platform.TENANT_ID=$AZ_TENANT_ID \
--plugin-env azure-arc-ds-platform.SUBSCRIPTION_ID=$AZ_SUBSCRIPTION_ID \
--plugin-env azure-arc-ds-platform.RESOURCE_GROUP=$RESOURCE_GROUP \
--plugin-env azure-arc-ds-platform.LOCATION=$LOCATION \
--plugin-env azure-arc-ds-platform.CLIENT_ID=$AZ_CLIENT_ID \
--plugin-env azure-arc-ds-platform.CLIENT_SECRET=$AZ_CLIENT_SECRET

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

az storage container create -n conformance-results --account-name $AZ_STORAGE_ACCOUNT --sas-token $AZ_STORAGE_ACCOUNT_SAS
az storage blob upload --file conformance-results.tar.gz --name conformance-results.tar.gz --container-name conformance-results --account-name $AZ_STORAGE_ACCOUNT --sas-token $AZ_STORAGE_ACCOUNT_SAS