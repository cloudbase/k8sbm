echo "---" > sealed_secrets_main.key
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml >> sealed_secrets_main.key

cat bmc-auth/bmc-altra-auth.yaml | kubeseal --controller-namespace kube-system --controller-name sealed-secrets --format yaml > config/management/machine/bmc-auth-machine1-sealed.yaml

