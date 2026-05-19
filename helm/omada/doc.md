helm upgrade --install omada-controller oci://registry-1.docker.io/mbentley/omada-controller-helm -f ./helm/omada/omada.values.yaml --namespace omada-controller --create-namespace --version 1.4.0

kubectl apply -f ./helm/omada/resources/