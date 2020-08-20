 # Arc certification for kubernetes

 Azure Arc aims at bringing management and services to any infrastructure. Deploy and manage applications on Kubernetes clusters everywhere using GitOps.  

While Azure Arc can be deployed on any K8s clusters, certification provides distinct visibility for integrated K8s platforms and promises quality, support and consistency for Azure Arc customers across hybrid clusters. 

To realize the promise of Arc feature consistency and high quality on partner platforms, we have build conformance test framework and automation to continuously test and validate the Arc functionality on certified platforms. Microsoft will take ownership of providing conformance tests covering Arc for Kubernetes functionality. We will continuously add to conformance test repo as we release functionality to get 100% coverage. 

## Asks from Partners for Conformance tests and integration

For managing consistency, we had like our certified partners to integrate the conformance tests in their CI/CD pipeline and publishing conformance tests results for major/minor release of partner distribution. 

### Partner Responsibility
- Partner runs the conformance tests for every major/minor version pre-releases of their Kubernetes distribution prior to at least 15 days of its public release. (both beta and production releases). 
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

sonobuoy run --plugin {Path to conformance.yaml} --plugin-env azure-arc-conformance.TENANT_ID=$TENANT_ID --plugin-env azure-arc-conformance.SUBSCRIPTION_ID=$SUBSCRIPTION_ID --plugin-env azure-arc-conformance.RESOURCE_GROUP=$RESOURCE_GROUP --plugin-env azure-arc-conformance.CLUSTER_NAME=$CLUSTER_NAME --plugin-env azure-arc-conformance.LOCATION=$LOCATION --plugin-env azure-arc-conformance.CLIENT_ID=$CLIENT_ID --plugin-env azure-arc-conformance.CLIENT_SECRET=$CLIENT_SECRET

Download the conformance.yaml from this github <a href="">in this repository</a>  

These two are required for conformance tests to connect kubernetes cluster to Arc on Azure. As stated before, conformance tests connects the cluster to Arc before running the tests.  
TENANT_ID - is tenantID of Azure subscription 
Subscription_ID - Azure Subscription ID

Cluster_Name : Name to give your cluster on Arc connection.
LOCATION : Region of Azure to connect the cluster to. Make sure you provide the regions supported by Azure Arc for Kubernetes. See [here]https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/connect-cluster for supported regions.  


The user should also specify --plugin-env azure-arc-conformance.KUBERNETES_DISTRIBUTION=$KUBERNETES_DISTRIBUTION for the arc conformance test to work properly. Also, sonobuoy assumes that the dns pods are present in the kube-system namespace. If a certain kubernetes distribution has different location for the dns pods, the user should provide that information in the above command through the flags '--dns-namespace' and '--dns-pod-labels'

By default, the arc conformance test does the cleanup after the test run. If the user wishes to skip the cleanup step, he should set --plugin-env azure-arc-conformance.SKIP_CLEANUP=true in the above command.

If you wish to run particular tests or skip particular tests, you need to set --plugin-env azure-arc-conformance.TEST_NAME_LIST=$TEST_NAME_LIST. The variable TEST_NAME_LIST should be set similar to -k flag of pytest. See https://docs.pytest.org/en/latest/example/markers.html#using-k-expr-to-select-tests-based-on-their-name

Similarly, you wish to run particular group of tests or skip particular group tests you need to set --plugin-env azure-arc-conformance.TEST_MARKER_LIST=$TEST_MARKER_LIST. The variable TEST_MARKER_LIST should be set similar to -m flag of pytest. See https://docs.pytest.org/en/2.9.2/example/markers.html#marking-test-functions-and-selecting-them-for-a-run

The status of the conformance test can be checked using the command 'sonobuoy status'.

Once the status is complete, run the command 'sonobuoy retrieve' to download the results tarball

These conformance tests , every partner needs to include Arc testing in their E2E testing for every prerelease of their distribution and Arc releases. This is a tall ask for partners without an automated Arc for Kubernetes testing suite provided by us for continued testing.

 ## Arc conformance tests

 Need of Arc conformance tests and process
 
 ## Run Arc conformance tests

 ### PreRequisities 
 
 
 #Arc for Kubernetes Conformance tests 
 Introduction and details arund this - Kavitha

#Prerequisites for running tests
--Akash link to our docs for Arc. 
for Tests- the sonobuoy installation

#Running Conformance tests
instructions - Akash
Add conformance.yaml in the repo here (under code)

#Output from Sonobuoy conformance test run
instructions- Akash
What files to look for 
How can they debug
Which is the test result file 
#Uploading results from conformance tests
-Kavitha : How to parse - upload, debug, raise issue. 

#Conformance test Guidelines
--Kavitha
#Violation of Arc certification with conformance tests 
--Kavitha
#List of tests run
-- mentionthe list of tests that we are running - Akash







##Arc for Kubernetes Conformance tests


#Arc for Kubernetes Conformance tests 
Introduction and details arund this - Kavitha

#Prerequisites for running tests
--Akash link to our docs for Arc. 
for Tests- the sonobuoy installation

#Running Conformance tests
instructions - Akash
Add conformance.yaml in the repo here (under code)

#Output from Sonobuoy conformance test run
instructions- Akash
What files to look for 
How can they debug
Which is the test result file 
#Uploading results from conformance tests
-Kavitha : How to parse - upload, debug, raise issue. 

#Conformance test Guidelines
--Kavitha
#Violation of Arc certification with conformance tests 
--Kavitha
#List of tests run
-- mentionthe list of tests that we are running - Akash

