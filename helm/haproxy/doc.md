helm repo add haproxytech https://haproxytech.github.io/helm-charts

helm repo update



helm upgrade --install haproxy haproxytech/haproxy  --version 1.29.0 -f ./helm/haproxy/haproxy.values.yaml --namespace haproxy --create-namespace