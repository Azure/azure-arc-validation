# Azure Arc Conformance test launcher script

declare -A properties
declare -A enabled_plugins

properties_count=0
plugin_count=0
repository="https://github.com/santosh02iiit/azure-arc-validation.git"

# Parsing azure-arc-conformance.properties
while IFS= read -r line; do
    # remove leading and trailing whitespaces
    line="$(echo -e "${line}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    if [[ "${line}" == "#"* ]] #ignore lines starting with comments
    then
        continue
    elif [ -z "${line}" ] #ignore empty lines
    then
        continue
    fi

    if [[ $line == *".enable="* ]] 
    then
        if [[ $line == *"true"* ]]
        then
            enabled_plugins[$plugin_count]=$(echo $line | cut -d. -f1)
            ((plugin_count++))
        fi
    
    elif [[ $line == *"dev-repository"* ]]
    then
        repository="${line#*=}"

    elif [[ $line == *"offering-name"* ]]
    then
        OFFERING_NAME="${line#*=}"

    elif [[ $line == *"az-storage-account-sas"* ]]
    then
        AZ_STORAGE_ACCOUNT_SAS="${line#*=}"
    
    elif [[ $line == *"az-storage-account"* ]]
    then
        AZ_STORAGE_ACCOUNT="${line#*=}"

    else
        properties[$properties_count]=$line
        ((properties_count++))
    fi

    if [[ $line == *"SUBSCRIPTION_ID"* ]]
    then
        AZ_SUBSCRIPTION_ID="${line#*=}"

    elif [[ $line == *"CLIENT_ID"* ]]
    then
        AZ_CLIENT_ID="${line#*=}"

    elif [[ $line == *"CLIENT_SECRET"* ]]
    then
        AZ_CLIENT_SECRET="${line#*=}"
    
    elif [[ $line == *"TENANT_ID"* ]]
    then
        AZ_TENANT_ID="${line#*=}"
    fi

done < /etc/config/azure-arc-conformance.properties
# Parsing ends

# Basic validation of required parameters
error=0
if [[ -z "${AZ_STORAGE_ACCOUNT_SAS}" ]]
then
    echo "Warning: Please set az-storage-account-sas in property file"
fi

if [[ -z "${AZ_STORAGE_ACCOUNT}" ]]
then
    echo "Warning: Please set az-storage-account in property file"
fi

if [[ -z "${AZ_SUBSCRIPTION_ID}" ]]
then
    echo "Error: Please set global.SUBSCRIPTION_ID in property file"
    error=1
fi

if [[ -z "${AZ_CLIENT_ID}" ]]
then
    echo "Error: Please set global.CLIENT_ID in property file"
    error=1
fi

if [[ -z "${AZ_CLIENT_SECRET}" ]]
then
    echo "Error: Please set global.CLIENT_SECRET in property file"
    error=1
fi

if [[ -z "${AZ_TENANT_ID}" ]]
then
    echo "Error: Please set global.TENANT_ID in property file"
    error=1
fi

if [[ error -eq 1 ]]
then
    exit
fi
# Parameter validation ends

az login --service-principal --username $AZ_CLIENT_ID --password $AZ_CLIENT_SECRET --tenant $AZ_TENANT_ID
az account set -s $AZ_SUBSCRIPTION_ID

# Url will be changed test code
echo "arc repository: $repository"
git clone $repository
cd /azure-arc-validation
git checkout -b launcher_VMwareProposal origin/launcher_VMwareProposal
cd /
# test code ends

plugins_files=(/azure-arc-validation/testsuite/conformance-test-plugins/*)

command="sonobuoy run --wait"
#check if yaml file is present for the user configuration
add_helm=0
found=0
for enabled_plugin in "${enabled_plugins[@]}"
do
    found=0
    for file in "${plugins_files[@]}"
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
                if [[ $var == $enabled_plugin* ]]
                then
                    command="${command} --plugin-env $var"
                elif [[ $var == "global"* ]]
                then
                    plugin_var="${var/"global"/"$enabled_plugin"}"
                    command="${command} --plugin-env $plugin_var"
                fi
            done            
            break
        fi
    done
    if [[ $found -eq 0 ]]
    then
        echo "Error: Plugins yaml file is not found on server please check the property for plugin: $enabled_plugin"
    fi
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

    az_storage_create_result=$(az storage container create -n $containerString --account-name $AZ_STORAGE_ACCOUNT --sas-token $AZ_STORAGE_ACCOUNT_SAS)
    az_storage_upload_result=$(az storage blob upload --file conformance-results-$arc_platform_version.tar.gz --name conformance-results-$OFFERING_NAME.tar.gz --container-name $containerString --account-name $AZ_STORAGE_ACCOUNT --sas-token $AZ_STORAGE_ACCOUNT_SAS)

    echo "Cleaning the cluster.."
    sonobuoy delete --wait

    if [[ $az_storage_create_result==*"ERROR"* || $az_storage_upload_result==*"ERROR"* ]]
    then
        echo "Result upload failed keeping the pod for 2 days for result fecthing"
        sleep 2d
    fi

    echo "Buffer wait 5 minutes..."
    sleep 5m

done < aak8sSupportPolicy.txt