ARG KSOPS_IMAGE=viaductoss/ksops:v4.5.1
FROM ${KSOPS_IMAGE}

# The upstream KSOPS image intentionally does not bundle SOPS. Argo CD needs
# both executables in the same CMP sidecar to render SOPS-encrypted manifests.
COPY sops /usr/local/bin/sops
USER 999
