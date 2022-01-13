ARG AZURE_CLI_VERSION
FROM mcr.microsoft.com/azure-cli:${AZURE_CLI_VERSION}

RUN /usr/bin/curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl  \
    &&  mv ./kubectl /usr/local/bin/kubectl

# Install python3
RUN apk add --update python3

COPY k8s-conformance-test-suite.sh /
COPY aak8sSupportPolicy.txt /
COPY config.json /
COPY partner-metadata.md /
COPY remove-secrets.py /

ARG SONOBUOY_VERSION
ADD https://github.com/vmware-tanzu/sonobuoy/releases/download/v${SONOBUOY_VERSION}/sonobuoy_${SONOBUOY_VERSION}_linux_arm64.tar.gz ./
RUN tar -xvf sonobuoy_${SONOBUOY_VERSION}_linux_arm64.tar.gz && rm sonobuoy_${SONOBUOY_VERSION}_linux_arm64.tar.gz
RUN mv sonobuoy /usr/local/bin/

ENTRYPOINT ["/bin/bash", "/k8s-conformance-test-suite.sh"]