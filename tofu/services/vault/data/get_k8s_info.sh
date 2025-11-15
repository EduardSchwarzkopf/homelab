TOKEN=$(kubectl get secret -n vault -o jsonpath='{.items[0].data.token}' | base64 -d)
HOST=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')
CA_CRT=$(kubectl get cm kube-root-ca.crt -o jsonpath="{['data']['ca\.crt']}")

jq -n \
    --arg host "$HOST" \
    --arg token "$TOKEN" \
    --arg ca_cert "$CA_CRT" \
    '{"ca_cert":$ca_cert,"token":$token,"host":$host}'