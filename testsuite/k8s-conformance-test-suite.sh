# Set the following environment variables to run the test suite

# Common Variables
# Some of the variables need to be populated from the service principal and storage account details provided to you by Microsoft
connectedClustedId=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 7 ; echo '')
AZ_TENANT_ID= # tenant field of the service principal
AZ_SUBSCRIPTION_ID= # subscription id of the azure subscription (will be provided)
AZ_CLIENT_ID= # appid field of the service principal
AZ_CLIENT_SECRET= # password field of the service principal
AZ_STORAGE_ACCOUNT= # name of your storage account (will be provided)
AZ_STORAGE_ACCOUNT_SAS= # sas token for your storage account, please add it within the quotes (will be provided)
RESOURCE_GROUP= # resource group name (will be provided)
OFFERING_NAME= # name of the partner offering; use this variable to distinguish between the results tar for different offerings
CLUSTERNAME=arc-partner-test-$connectedClustedId # name of the arc connected cluster
LOCATION=eastus # location of the arc connected cluster

# Platform Cleanup Plugin
CLEANUP_TIMEOUT=1500 # time in seconds after which the platform cleanup plugin times out

# In case your cluster is behind an outbound proxy, please add the following environment variables in the below command
# --plugin-env azure-arc-platform.HTTPS_PROXY="http://<proxy ip>:<proxy port>"
# --plugin-env azure-arc-platform.HTTP_PROXY="http://<proxy ip>:<proxy port>"
# --plugin-env azure-arc-platform.NO_PROXY="kubernetes.default.svc,<ip CIDR etc>"

# In case your outbound proxy is setup with certificate authentication, follow the below steps:
# Create a Kubernetes generic secret with the name sonobuoy-proxy-cert with key proxycert in any namespace:
# kubectl create secret generic sonobuoy-proxy-cert --from-file=proxycert=<path-to-cert-file>
# By default we check for the secret in the default namespace. In case you have created the secret in some other namespace, please add the following variables in the sonobuoy run command: 
# --plugin-env azure-arc-platform.PROXY_CERT_NAMESPACE="<namespace of sonobuoy secret>"
# --plugin-env azure-arc-agent-cleanup.PROXY_CERT_NAMESPACE="namespace of sonobuoy secret"

az login --service-principal --username $AZ_CLIENT_ID --password $AZ_CLIENT_SECRET --tenant $AZ_TENANT_ID
az account set -s $AZ_SUBSCRIPTION_ID

# read config file i.e., azure-arc-conformance.properties
declare -A properties
declare -A enabled_plugins

properties_count=0
plugin_count=0

# more santiation required in below code
# case 1: empty spaces/newlines before and after
# case 2: ignore comments starting with #

while IFS= read -r line; do
    echo "current line: $line"
    if [[ $line == *"enable"* ]] 
    then
        if [[ $line == *"true"* ]]
        then
            enabled_plugins[$plugin_count]=$(echo $line | cut -d. -f1)
            echo "adding plugins: $plugin_count"
            echo "added plugins: ${enabled_plugins[$plugin_count]}"
            ((plugin_count++))
            
        fi
    else
        properties[$properties_count]=$line
        echo "adding properties: $properties_count"
        echo "added properties: ${properties[$properties_count]}"
        ((properties_count++))
    fi
done < /etc/config/azure-arc-conformance.properties

# Url will be changed test code
git clone "https://github.com/santosh02iiit/azure-arc-validation.git"
cd /azure-arc-validation
git checkout -b launcher_VMwareProposal origin/launcher_VMwareProposal
cd /
# test code ends

plugins_file=(/azure-arc-validation/testsuite/conformance-test-plugins/*)

command="sonobuoy run --wait"
#check if yaml file is present for the user configuration
add_helm=0
found=0
for enabled_plugin in "${enabled_plugins[@]}"
do
    for file in "${plugins_file[@]}"
    do
        if [[ $file == *$enabled_plugin* ]] 
        then
            found=1
            if [[ $enabled_plugin == "azure-arc-platform" ]]
            then
                add_helm=1
            fi
            # prepare the command 
            command="${command} --plugin $file" 
            # get all the variables
            for var in "${properties[@]}"
            do
                if [[ $var == *$enabled_plugin* ]]
                then
                    command="${command} --plugin-env $var"
                elif [[ $var == *"global"* ]]
                then
                    plugin_var="${var/"global"/"$enabled_plugin"}"
                    echo "new var $plugin_var"
                    command="${command} --plugin-env $plugin_var"
                fi
            done            
            break
        fi
    done
    if [[ $found -eq 0 ]]
    then
        echo "Plugins yaml file is not found on server please check the property"
done

command="${command} --config config.json" 

while IFS= read -r arc_platform_version || [ -n "$arc_platform_version" ]; do

    echo "Running the test suite for Arc for Kubernetes version: ${arc_platform_version}"    

    if [[ $add_helm -eq 1 ]]
    then
        eval "$command --plugin-env azure-arc-platform.HELMREGISTRY=mcr.microsoft.com/azurearck8s/batch1/stable/azure-arc-k8sagents:$arc_platform_version"
    else
        eval $command
    fi
    echo "Test execution completed..Retrieving results"

    sonobuoyResults=$(sonobuoy retrieve)
    sonobuoy results $sonobuoyResults

    mkdir testResult
    python remove-secrets.py $sonobuoyResults testResult

    rm -rf testResult
    mkdir results
    mv $sonobuoyResults results/$sonobuoyResults
    cp partner-metadata.md results/partner-metadata.md
    tar -czvf conformance-results-$arc_platform_version.tar.gz results
    rm -rf results

    echo "Publishing results.."

    IFS='.'
    read -ra version <<< $arc_platform_version
    containerString="conformance-results-major-${version[0]}-minor-${version[1]}-patch-${version[2]}"
    IFS=$' \t\n'

    az storage container create -n $containerString --account-name $AZ_STORAGE_ACCOUNT --sas-token $AZ_STORAGE_ACCOUNT_SAS
    az storage blob upload --file conformance-results-$arc_platform_version.tar.gz --name conformance-results-$OFFERING_NAME.tar.gz --container-name $containerString --account-name $AZ_STORAGE_ACCOUNT --sas-token $AZ_STORAGE_ACCOUNT_SAS

    echo "Cleaning the cluster.."
    sonobuoy delete --wait

    echo "Buffer wait 5 minutes..."
    sleep 5m

done < aak8sSupportPolicy.txt