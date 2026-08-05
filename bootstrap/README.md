# GitOps bootstrap

Bootstrap installs Traefik chart `41.1.1`, Argo CD chart `10.2.3`, and KSOPS
`v4.5.1`. It needs a readable age identity through `SOPS_AGE_KEY_FILE`; the
identity is created only as the `gitops/argocd-sops-age` Secret and is never
written into this repository.

Run only after reviewing the rendered change and obtaining explicit stateful
cutover approval:

```bash
SOPS_AGE_KEY_FILE=/path/to/keys.txt KUBE_CONTEXT=orbstack ./scripts/bootstrap-gitops.sh
```

The script uses atomic Helm operations. On a chart failure Helm rolls back its
release, but the `ingress`, `gitops`, key Secret, and plugin ConfigMap remain
for inspection and must be removed only through an approved recovery action.
