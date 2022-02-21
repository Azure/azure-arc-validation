#!/usr/bin/env bash

#
#   Azure Arc K8s conformance test script
#
# Before running the test, create the vars file and fill it:
# $ cp ./.env-platform.sample ./.env-platform
#
# In case your cluster is behind an outbound proxy, please add the following environment variables in the below command
# --plugin-env azure-arc-platform.HTTPS_PROXY="http://<proxy ip>:<proxy port>"
# --plugin-env azure-arc-platform.HTTP_PROXY="http://<proxy ip>:<proxy port>"
# --plugin-env azure-arc-platform.NO_PROXY="kubernetes.default.svc,<ip CIDR etc>"
#
# In case your outbound proxy is setup with certificate authentication, follow the below steps:
# Create a Kubernetes generic secret with the name sonobuoy-proxy-cert with key proxycert in any namespace:
# kubectl create secret generic sonobuoy-proxy-cert --from-file=proxycert=<path-to-cert-file>
# By default we check for the secret in the default namespace. In case you have created the secret in some other namespace, please add the following variables in the sonobuoy run command: 
# --plugin-env azure-arc-platform.PROXY_CERT_NAMESPACE="<namespace of sonobuoy secret>"
# --plugin-env azure-arc-agent-cleanup.PROXY_CERT_NAMESPACE="namespace of sonobuoy secret"

# Loading variables file
VAR_FILE=./.env-platform
if [[ ! -f ${VAR_FILE} ]]; then
    echo "Unable to find variables file. Have you created it from sample ${VAR_FILE}-sample"
    exit 1
fi
source ${VAR_FILE}

az login --service-principal --username $AZ_CLIENT_ID --password $AZ_CLIENT_SECRET --tenant $AZ_TENANT_ID
az account set -s $AZ_SUBSCRIPTION_ID

declare -g sonobuoyResults

DT_EXEC_TMP="$(date +%Y%m%d%H%M)"
RESULT_DIR="./results-archive-${DT_EXEC_TMP}"
mkdir ${RESULT_DIR}
echo ">> Results will be saved on: ${RESULT_DIR}"

# OpenShift debug only: used to collect OCP log when sonobuoy fails with EOF error
collect_sonobuoy_results() {
    sleep 10;
    echo "# Finding the node running sonobuoy container"
    local node_pod=$(oc get pods -n sonobuoy sonobuoy -o jsonpath='{.spec.nodeName}')

    echo "# Get containerId and meta"
    local cid_pod=$(oc debug node/$node_pod -- chroot /host /bin/bash -c "crictl ps |grep sonobuoy " 2>/dev/null |awk '{print$1}')

    oc debug node/$node_pod -- chroot /host /bin/bash -c "crictl inspect ${cid_pod}"  2>/dev/null > ${RESULT_DIR}/container-inspect-sonobuoy.json

    echo "# Retrieve results ephemeral storage path on node"
    local volume_path=$(jq -r '.info.runtimeSpec.mounts[] | select(.destination=="/tmp/sonobuoy") |.source' ${RESULT_DIR}/container-inspect-sonobuoy.json)

    echo "# Collect all the results available on container path"
    #mkdir -p results/
    for result_file in $(oc debug node/$node_pod -- chroot /host /bin/bash -c "ls ${volume_path}"  2>/dev/null ); do

        echo "# Collecting file $RESULT";
        oc debug node/$node_pod -- chroot /host /bin/bash -c "cat ${volume_path}/${result_file}" > ${result_file}

        ls -lsha ${result_file}
        sonobuoyResults=${result_file}

        echo "Extracting results..."
        filename=$(basename -s .tar.gz $result_file)
        mkdir ${RESULT_DIR}/$filename
        tar xf ${result_file}  -C ${RESULT_DIR}/$filename plugins/azure-arc-platform/sonobuoy_results.yaml

        echo "sonobuoy_results was extracted to: ${RESULT_DIR}/$filename/plugins/azure-arc-platform/sonobuoy_results.yaml"
        echo "Show results: "
        cat ${RESULT_DIR}/$filename/plugins/azure-arc-platform/sonobuoy_results.yaml
    done
}

# OpenShift debug only: Patch kube-aad-proxy to allow SCC
patch_kube_aad_proxy() {
  local cnt=0
  while $(test -z $(oc -n azure-arc get deployment -l app.kubernetes.io/component=kube-aad-proxy -o jsonpath="{.items[*].metadata.name}")); do test ${cnt} -eq 20 && return; let "cnt++"; echo $cnt; sleep 20; done
  echo "#> Running patch to kube-aad-proxy"
  oc \
    patch deployment.apps/kube-aad-proxy -n azure-arc \
    --type='json' \
    -p='[{"op": "replace", "path": "/spec/template/spec/containers/1/securityContext", "value":{"privileged": true, "runAsGroup": 0,"runAsUser": 0}}]'
}

# OpenShift debug only: dump NSs
backup_results() {
    echo "# collecting NS dump"
    oc adm inspect ns/sonobuoy ns/azure-arc ns/default --dest-dir=${RESULT_DIR}/ns-inspect
}

# OpenShift debug only: check if provider was created
az_provider_show() {
    az provider show -n Microsoft.Kubernetes -o table;
    az provider show -n Microsoft.KubernetesConfiguration -o table;
    az provider show -n Microsoft.ExtendedLocation -o table ;
}

# OpenShift debug only: required to test elevate cluter privileges like accessing hostPath,
# from conformance test pods. ToDo check how to avoid it.
apply_scc_fixes() {
    # overriding the same of OSD for k8s-conformance: https://github.com/cncf/k8s-conformance/tree/master/v1.22/openshift-dedicated#running-conformance
    oc adm policy add-scc-to-group privileged system:authenticated system:serviceaccounts
    oc adm policy add-scc-to-group anyuid system:authenticated system:serviceaccounts

    oc patch scc restricted \
    --type='json' \
    -p='[{"op": "replace", "path": "/allowHostDirVolumePlugin", "value":true},{"op": "replace", "path": "/allowPrivilegedContainer", "value":true}]'
}
apply_scc_fixes

# OpenShift debug only: force delete all objects (avoid leak from delete subcommand)
clean_up_resources() {
    sonobuoy delete --wait

    # Make all the resources was removed
    oc delete project azure-arc
    oc delete project sonobuoy

    # Those secrets has been leaked on default namespace
    oc delete secret sh.helm.release.v1.azure-arc.v1 -n default
    oc delete secret sh.helm.release.v1.azure-arc.v2 -n default

    #ToDo: delete Azure Arc object from Azure (need it?)
    # delete arc service from RG (Azure Console)
    #> List
    #az connectedk8s list --resource-group $RESOURCE_GROUP -o table
    #az_provider_show
    #> Delete
    #for ARC_NAME in $(az connectedk8s list  --resource-group $RESOURCE_GROUP  -o json |jq -r .[].name); do az connectedk8s delete --name $ARC_NAME  --resource-group $RESOURCE_GROUP ; done
}
clean_up_resources

# run the test for each varsion
while IFS= read -r arc_platform_version || [ -n "$arc_platform_version" ]; do

    echo "Running the test suite for Arc for Kubernetes version: ${arc_platform_version}"    

    #> Patch to make sure SCC has the less restrictive permissions to run Arc Validation
    #>> removing it for a while to test it in newer versions:
    #>> arck8sconformance.azurecr.io/arck8sconformance/clusterconnect:0.1.7
    #patch_kube_aad_proxy &

    sonobuoy run --wait \
    --plugin arc-k8s-platform/platform.yaml \
    --plugin-env azure-arc-platform.TENANT_ID=$AZ_TENANT_ID \
    --plugin-env azure-arc-platform.SUBSCRIPTION_ID=$AZ_SUBSCRIPTION_ID \
    --plugin-env azure-arc-platform.RESOURCE_GROUP=$RESOURCE_GROUP \
    --plugin-env azure-arc-platform.CLUSTER_NAME=$CLUSTERNAME \
    --plugin-env azure-arc-platform.LOCATION=$LOCATION \
    --plugin-env azure-arc-platform.CLIENT_ID=$AZ_CLIENT_ID \
    --plugin-env azure-arc-platform.CLIENT_SECRET=$AZ_CLIENT_SECRET \
    --plugin-env azure-arc-platform.HELMREGISTRY=mcr.microsoft.com/azurearck8s/batch1/stable/azure-arc-k8sagents:$arc_platform_version \
    --plugin arc-k8s-platform/cleanup.yaml \
    --plugin-env azure-arc-agent-cleanup.TENANT_ID=$AZ_TENANT_ID \
    --plugin-env azure-arc-agent-cleanup.SUBSCRIPTION_ID=$AZ_SUBSCRIPTION_ID \
    --plugin-env azure-arc-agent-cleanup.RESOURCE_GROUP=$RESOURCE_GROUP \
    --plugin-env azure-arc-agent-cleanup.CLUSTER_NAME=$CLUSTERNAME \
    --plugin-env azure-arc-agent-cleanup.CLEANUP_TIMEOUT=$CLEANUP_TIMEOUT \
    --plugin-env azure-arc-agent-cleanup.CLIENT_ID=$AZ_CLIENT_ID \
    --plugin-env azure-arc-agent-cleanup.CLIENT_SECRET=$AZ_CLIENT_SECRET \
    --plugin-env azure-arc-platform.OBJECT_ID=$AZ_OBJECT_ID \
    --config config.json \
    --dns-namespace="${DNS_NAMESPACE}" \
    --dns-pod-labels="${DNS_POD_LABELS}"

    echo "Test execution completed..Retrieving results"

    sonobuoyResults=$(sonobuoy retrieve)
    sonobuoy results $sonobuoyResults

    # mkdir ${RESULT_DIR}/testResult-$arc_platform_version
    # python arc-k8s-platform/remove-secrets.py $sonobuoyResults ${RESULT_DIR}/testResult-$arc_platform_version

    #>>>> Patch to remove secretes starts here
    # OpenShift collector when 'sonobuoy retrieve' fails with 'EOF'
    test -z $sonobuoyResults && collect_sonobuoy_results

    # backup current results
    res_filename="$(basename -s .tar.gz $sonobuoyResults)"
    cp -v $sonobuoyResults "${res_filename}-bkp.tar.gz"

    # clean secrets (1): the original file will be overrided
    res_tmp="${RESULT_DIR}/testResult-$arc_platform_version"
    mkdir -p ${res_tmp}
    python arc-k8s-platform/remove-secrets.py $sonobuoyResults ${res_tmp}
    rm -rf ${res_tmp}

    # clean secret (2)
    res_tmp="${RESULT_DIR}/.tmp-testResult-$arc_platform_version"
    mkdir -p ${res_tmp}
    tar xfz $sonobuoyResults -C ${res_tmp}
    echo "# Reporting files with credential AZ_CLIENT_SECRET: "
    grep -rl $AZ_CLIENT_SECRET ${res_tmp}

    echo "# Redacting credential AZ_CLIENT_SECRET: "
    grep -rl $AZ_CLIENT_SECRET ${res_tmp} |xargs sed -i "s/${AZ_CLIENT_SECRET}/[REDACTED]/g"

    # copy partner metadata
    cp partner-metadata.md ${res_tmp}/partner-metadata.md

    res_cwd=$PWD
    pushd ${res_tmp}
    tar cfJ "${res_cwd}/${res_filename}-redacted.tar.xz" *
    popd
    rm -rf ${res_tmp}
    mv -v ${res_cwd}/${res_filename}* ${RESULT_DIR}

    #>>>> Patch to remove secretes ends here

    # #rm -rf testResult-$arc_platform_version
    # RESULTS_NAME="results-$arc_platform_version"
    # mkdir ${RESULT_DIR}/${RESULTS_NAME}
    # mv $sonobuoyResults ${RESULT_DIR}/${RESULTS_NAME}/$sonobuoyResults
    # cp partner-metadata.md ${RESULT_DIR}/${RESULTS_NAME}/partner-metadata.md
    # tar -czvf conformance-${RESULTS_NAME}.tar.gz ${RESULT_DIR}/${RESULTS_NAME}
    #rm -rf ${RESULTS_PATH}/${RESULTS_NAME}

    echo "Publishing results... (ignoring for now)"
    # IFS='.'
    # read -ra version <<< $arc_platform_version
    # containerString="${DT_EXEC_TMP}-conformance-results-major-${version[0]}-minor-${version[1]}-patch-${version[2]}"
    # IFS=$' \t\n'

    #az storage container create -n $containerString --account-name $AZ_STORAGE_ACCOUNT --sas-token $AZ_STORAGE_ACCOUNT_SAS
    #az storage blob upload --file conformance-${RESULTS_DIR}.tar.gz --name conformance-results-$OFFERING_NAME.tar.gz --container-name $containerString --account-name $AZ_STORAGE_ACCOUNT --sas-token $AZ_STORAGE_ACCOUNT_SAS

    # test $(az storage account check-name -n $AZ_STORAGE_ACCOUNT |jq .nameAvailable) && \
    #     az storage account create -n $AZ_STORAGE_ACCOUNT -g ${RESOURCE_GROUP}
    # az storage container create -n $containerString --account-name $AZ_STORAGE_ACCOUNT -g ${RESOURCE_GROUP}
    # az storage blob upload --file conformance-${RESULTS_DIR}.tar.gz --name conformance-results-$OFFERING_NAME.tar.gz --container-name $containerString --account-name $AZ_STORAGE_ACCOUNT

    echo "Cleaning the cluster... (ignoring for now)"
    #clean_up_resources

    echo "Buffer wait 5 minutes..."
    #sleep 5m

done < aak8sSupportPolicy.txt

pushd $RESULT_DIR
tar cf ${RESULT_DIR}.tar *-redacted.tar.xz
popd
