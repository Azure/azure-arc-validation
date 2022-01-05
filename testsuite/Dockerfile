FROM mcr.microsoft.com/azure-cli:2.29.0

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

RUN mkdir /arc-k8s-platform
COPY arc-k8s-platform/remove-secrets.py /arc-k8s-platform/
COPY arc-k8s-platform/cleanup.yaml /arc-k8s-platform/
COPY arc-k8s-platform/platform.yaml /arc-k8s-platform/

# Install sonobuoy
ADD https://github.com/vmware-tanzu/sonobuoy/releases/download/v0.55.1/sonobuoy_0.55.1_linux_arm64.tar.gz ./
RUN tar -xvf sonobuoy_0.55.1_linux_arm64.tar.gz && rm sonobuoy_0.55.1_linux_arm64.tar.gz
RUN mv sonobuoy /usr/local/bin/

ENTRYPOINT ["/bin/bash", "/k8s-conformance-test-suite.sh"]