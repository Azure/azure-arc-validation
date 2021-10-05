# Set the following environment variables to run the test suite

# Common Variables
# Some of the variables need to be populated from the service principal and storage account details provided to you by Microsoft

import random
import string
import os
import subprocess
import shutil
import tarfile

from azure.mgmt.resource import SubscriptionClient
from azure.identity import ClientSecretCredential
from azure.storage.blob import ContainerClient

connectedClustedId = ''.join(random.choices(string.ascii_uppercase + string.digits, k = 7))

AZ_TENANT_ID="8548a469-8c0e-4aa4-b534-ac75ca1e02f7" # tenant field of the service principal, please add it within the quotes
AZ_SUBSCRIPTION_ID="3959ec86-5353-4b0c-b5d7-3877122861a0" # subscription id of the azure subscription (will be provided), please add it within the quotes
AZ_CLIENT_ID="27eb2e73-6520-4676-9f36-8dcc4b07efe3" # appid field of the service principal, please add it within the quotes
AZ_CLIENT_SECRET="GnxI5n2AZltrqIfW2.tV4_THYLKGPgqHzB" # password field of the service principal, please add it within the quotes
AZ_STORAGE_ACCOUNT="arcvalidationsa" # name of your storage account, please add it within the quotes
AZ_STORAGE_ACCOUNT_SAS="?sv=2020-08-04&ss=bfqt&srt=sco&sp=rwdlacuptfx&se=2021-10-09T14:59:39Z&st=2021-10-05T06:59:39Z&spr=https&sig=YxYm%2FKdmEfpQJybs4DC0%2FQTB%2B%2BersVC0nK3XuNaK5k0%3D" # sas token for your storage account, please replace <your-sas-token-here> with the actual value
RESOURCE_GROUP="external-test" # resource group name; set this to the resource group provided to you; please add it within the quotes
OFFERING_NAME="suvankartest123" # name of the partner offering; use this variable to distinguish between the results tar for different offerings
CLUSTERNAME="arc-partner-test"+connectedClustedId # name of the arc connected cluster
LOCATION="eastus" # location of the arc connected cluster

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

credential = ClientSecretCredential(tenant_id=AZ_TENANT_ID, client_id=AZ_CLIENT_ID, client_secret=AZ_CLIENT_SECRET)

subscription_client = SubscriptionClient(credential)

subscription = next(subscription_client.subscriptions.list())
print(subscription.subscription_id)

def make_tarfile(output_filename, source_dir):
    with tarfile.open(output_filename, "w:gz") as tar:
        tar.add(source_dir, arcname=os.path.basename(source_dir))  

optputFolderName = "results"
with open("testsuite/aak8sSupportPolicy.txt", "r") as f:
    arc_platform_version = [line.rstrip() for line in f]

print(arc_platform_version)

for version in arc_platform_version:
    print("Running the test suite for Arc for Kubernetes version:",version )

    sonobuoyRunCommand = f'sonobuoy run --wait ' \
         '--plugin testsuite/arc-k8s-platform/platform.yaml ' \
         '--plugin-env azure-arc-platform.TENANT_ID={AZ_TENANT_ID} ' \
         '--plugin-env azure-arc-platform.SUBSCRIPTION_ID={AZ_SUBSCRIPTION_ID} ' \
         '--plugin-env azure-arc-platform.RESOURCE_GROUP={RESOURCE_GROUP} ' \
         '--plugin-env azure-arc-platform.CLUSTER_NAME={CLUSTERNAME} ' \
         '--plugin-env azure-arc-platform.LOCATION={LOCATION} ' \
         '--plugin-env azure-arc-platform.CLIENT_ID={AZ_CLIENT_ID} ' \
         '--plugin-env azure-arc-platform.CLIENT_SECRET={AZ_CLIENT_SECRET} ' \
         '--plugin-env azure-arc-platform.HELMREGISTRY=mcr.microsoft.com/azurearck8s/batch1/stable/azure-arc-k8sagents:{version} ' \
         '--plugin testsuite/arc-k8s-platform/cleanup.yaml ' \
         '--plugin-env azure-arc-agent-cleanup.TENANT_ID={AZ_TENANT_ID} ' \
         '--plugin-env azure-arc-agent-cleanup.SUBSCRIPTION_ID={AZ_SUBSCRIPTION_ID} ' \
         '--plugin-env azure-arc-agent-cleanup.RESOURCE_GROUP={RESOURCE_GROUP} ' \
         '--plugin-env azure-arc-agent-cleanup.CLUSTER_NAME={CLUSTERNAME} ' \
         '--plugin-env azure-arc-agent-cleanup.CLEANUP_TIMEOUT={CLEANUP_TIMEOUT} ' \
         '--plugin-env azure-arc-agent-cleanup.CLIENT_ID={AZ_CLIENT_ID} ' \
         '--plugin-env azure-arc-agent-cleanup.CLIENT_SECRET={AZ_CLIENT_SECRET}'       

    print("Test execution completed..Retrieving results")    

    sonobuoyRunCommandResult = subprocess.run(sonobuoyRunCommand)    

    sonobuoyretrieveCommand = "sonobuoy retrieve" 
    sonobuoyresultFile = subprocess.run(sonobuoyretrieveCommand,capture_output=True, text=True).stdout.strip("\n")     

    sonobuoyResultsCommand = f"sonobuoy results {sonobuoyresultFile}"
    sonobuoyResultsCommandResult = subprocess.run(sonobuoyResultsCommand)    

    os.makedirs(optputFolderName)
    shutil.move(sonobuoyresultFile, optputFolderName) 
    shutil.copy("testsuite/partner-metadata.md",optputFolderName)
    tarFileName = f"conformance-results-{version}.tar.gz"
    make_tarfile(tarFileName,optputFolderName)
    shutil.rmtree(optputFolderName)

    print("Publishing results..") 
    versionArry = version.split('.')

    containerString = f"conformance-results-major-{versionArry[0]}-minor-{versionArry[1]}-patch-{versionArry[2]}"   

    sas_url = f"https://{AZ_STORAGE_ACCOUNT}.blob.core.windows.net/{containerString}{AZ_STORAGE_ACCOUNT_SAS}"
    container = ContainerClient.from_container_url(sas_url)

    if not container.exists():
        container.create_container()

    blobName = f"conformance-results-{OFFERING_NAME}.tar.gz"    

    blob_client = container.get_blob_client(blobName)   
    # Upload the created file
    with open(tarFileName, "rb") as data:
        blob_client.upload_blob(data,blob_type="BlockBlob")

    print("Cleaning the cluster..")    

    subprocess.run("sonobuoy delete --wait")