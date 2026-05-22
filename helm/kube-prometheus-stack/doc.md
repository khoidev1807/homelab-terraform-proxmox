helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 

helm repo update

helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack --version 85.2.0 -f ./helm/kube-prometheus-stack/kube-prometheus-stack.values.yaml --namespace monitoring --create-namespace

kubectl apply -f ./helm/kube-prometheus-stack/resources/