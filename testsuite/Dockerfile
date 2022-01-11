# Use default azure-cli version 2.29.0 if no version is specified in build
ARG AZURE_CLI_VERSION=2.29.0
FROM mcr.microsoft.com/azure-cli:${AZURE_CLI_VERSION}

RUN /usr/bin/curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl  \
    &&  mv ./kubectl /usr/local/bin/kubectl

# Install python3
RUN apk add --update python3

COPY kustomization.yaml /

COPY launch.yaml /

COPY k8s-conformance-test-suite.sh /

COPY aak8sSupportPolicy.txt /

COPY config.json /

COPY partner-metadata.md /

COPY remove-secrets.py /

# Install sonobuoy if no version is specified use default 0.55.1
ARG SONOBUOY_VERSION=0.55.1
ADD https://github.com/vmware-tanzu/sonobuoy/releases/download/v${SONOBUOY_VERSION}/sonobuoy_${SONOBUOY_VERSION}_linux_arm64.tar.gz ./
RUN tar -xvf sonobuoy_${SONOBUOY_VERSION}_linux_arm64.tar.gz && rm sonobuoy_${SONOBUOY_VERSION}_linux_arm64.tar.gz
RUN mv sonobuoy /usr/local/bin/

ENTRYPOINT ["/bin/bash", "/k8s-conformance-test-suite.sh"]