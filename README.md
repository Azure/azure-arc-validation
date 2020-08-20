 # Arc certification for kubernetes

 Azure Arc aims at bringing management and services to any infrastructure. Deploy and manage applications on Kubernetes clusters everywhere using GitOps.  

While Azure Arc can be deployed on any K8s clusters, certification provides distinct visibility for integrated K8s platforms and promises quality, support and consistency for Azure Arc customers across hybrid clusters. 

To realize the promise of Arc feature consistency and high quality on partner platforms, we have build conformance test framework and automation to continuously test and validate the Arc functionality on certified platforms. Microsoft will take ownership of providing conformance tests covering Arc for Kubernetes functionality. We will continuously add to conformance test repo as we release functionality to get 100% coverage. 

## Asks from Partners for Conformance tests and integration

For managing consistency, we had like our certified partners to integrate the conformance tests in their CI/CD pipeline and publishing conformance tests results for major/minor release of partner distribution. 

### Partner Responsibility
- Partner runs the conformance tests for every major/minor version pre-releases/stable releases of their Kubernetes distribution prior to at least 15 days of its public release. (both beta and production releases). 
- Partner to include the conformance testing in their CI/CD pipeline.
- Partner publishes the conformance test results emitted by test automation tool, sonobuoy, into partner results folder on certification GitHub repository. 
    - Partner K8s distro version is conformant when test results are positive. 
    - If test suite failed, partner can verify failure reason emitted by the test automation tool and optionally raise an issue on certification GitHub for Microsoft review. 
    - Partners should aim to resolve Arc conformance issue before taking release to customers.   

### Microsoft Responsibility 
Microsoft builds conformance tests and test automation tool, sonobuoy plugin, to run on partner distribution. 
- Microsoft provides the conformance test suite and sonobuoy plugin to run conformance tests with single command line run. 
    - Microsoft will continuously provide test coverage as feature evolves on Arc. 
- Microsoft integrates conformance tests in its E2E Arc K8s testing and validates these tests on partner distribution for every major/minor version releases of Arc K8s. 
- In case of severity 1/2 (blockers) errors in conformance testing on partner distribution, Microsoft debugs and fixes the issue in tangent with partner team, if needed, before releasing the Arc K8s version in question.     
- Microsoft gives partner access to Arc for Kubernetes latest release version 7-15 days prior to release to public, enabling partners to run conformance tests on their side, if needed. 
- Microsoft will provide issue tracking in case of bugs raised by partner and aim to respond to bugs within 7 days. 

# Running conformance tests

You can find list of conformance test <a href="https://github.com">here</a>  

Follow below to run conformance tests

## Prerequisites 

Install sonobuoy. See: https://github.com/vmware-tanzu/sonobuoy/releases You need to download a suitable sonobuoy version based on the kubernetes version of your cluster.

Conformance test installs the Arc for Kubernetes on cluster. Ensure to use a non-Arc connected cluster to run conformance tests. 

Make sure <a href="https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/connect-cluster">prereqs</a> required for Arc for Kubernetes installation are in place.

## Running conformance tests

Run Arc for Kubernetes conformance test by single command. 

sonobuoy run --plugin {Path to <a href="/conformance.yaml">Azure arc conformance yaml</a>} --plugin-env azure-arc-conformance.TENANT_ID=$TENANT_ID --plugin-env azure-arc-conformance.SUBSCRIPTION_ID=$SUBSCRIPTION_ID --plugin-env azure-arc-conformance.RESOURCE_GROUP=$RESOURCE_GROUP --plugin-env azure-arc-conformance.CLUSTER_NAME=$CLUSTER_NAME --plugin-env azure-arc-conformance.LOCATION=$LOCATION --plugin-env azure-arc-conformance.CLIENT_ID=$CLIENT_ID --plugin-env azure-arc-conformance.CLIENT_SECRET=$CLIENT_SECRET --plugin-env azure-arc-conformance.KUBERNETES_DISTRIBUTION=$KUBERNETES_DISTRIBUTION --plugin-env azure-arc-conformance.dns-namespace=$DNS_NAMESPACE -plugin-env azure-arc-conformance.dns-pod-labels=$DNS_POD_LABELS 

Download the conformance.yaml from <a href="/conformance.yaml">here, in this repo</a>  

In case of failure and to rerun the above command, delete sonobuoy pods and namespace by calling *sonobuoy delete*

### Parameters

- **TENANT_ID (Required)** : is tenantID of Azure subscription 
- **Subscription_ID (Required)** : Azure Subscription ID
- **Resource_group (Required)** : Azure resource group
- **Cluster_Name (Required)** : Name to give your cluster on Arc connection.
- **LOCATION (Required)** : Region of Azure to connect the cluster to. Make sure you provide the regions supported by Azure Arc for Kubernetes. See <a href="https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/connect-cluster">here</a> for supported regions.  
- **Client_ID** : App_ID of a service principal. You can reuse service Principal, make sure to assign the following minimal permission for your service principal 
                $ az role assignment create --role "Kubernetes Cluster - Azure Arc Onboarding" --assignee <<SP_APP_ID>> --subscription ${SUBSCRIPTION_ID} 
- **Client_secret** : Password of service principal. 
- **Kubernetes_distribution (optional)** - Needed only for Openshift clusters, in case of openshift, value should be "openshift"
- **dns-namespace (optional)** :  If a certain kubernetes distribution has different location for the dns pods, the user should provide that information in the above command through the flags '--dns-namespace' and '--dns-pod-labels'
- **dns-pod-labels (optional)** : If a certain kubernetes distribution has different location for the dns pods, the user should provide that information in the above command through the flags '--dns-namespace' and '--dns-pod-labels'


## Clean Up

By default, the arc conformance test does the cleanup arc components after the test run. If the user wishes to skip the cleanup step,  set --plugin-env azure-arc-conformance.SKIP_CLEANUP=true in the above command.

## Status Check

The status of the conformance test can be checked using the command **'sonobuoy status'**.

Once the status is complete, run the command **'sonobuoy retrieve'** to download the results zip file. 

### Result file
The zip file contains the results file at location **plugins/azure-arc-conformance/sonobuoy results.yaml**. This file has the summary of individual tests and their test status (pass/fail) that were run as a part of the test. If all the tests have passed, you will upload this file the <a href=/results"> Results</a> folder. 
 
 For failed tests, further look into **podlogs/sonobuoy/sonobuoy-azure-arc-conformance-job-GUID/plugin** file for error description. 
 
 When error cannot be resolved and want to raise issue, please share XXX.tar.gz generated by the sonobuoy. 

# Upload Results 

If **sonobuoy status** returns success,  run the command **'sonobuoy retrieve'** to download the results zip file. Retrieve **sonobuoy_results.yaml** from *plugins/azure-arc-conformance/sonobuoy_results.yaml* folder and upload to  <a href="/Results"> Results</a> folder.
 
Under Results/<<Partner Name>> folder, create a folder with your distribution version(Major.minor). Upload the results.yaml file under this folder. 
 
 For example: Results/Azure Stack-AKS Engine, you will create a folder called 1.2 ( version of AKS Engine on which the conformance tests were run). 
 
 # List of conformance tests
 <a href="catalog.md">Here</a> is the catalog of conformance tests. 
