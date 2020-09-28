git clone https://github.com/nginxinc/kubernetes-ingress.git
cd kubernetes-ingress/deployments
git checkout v1.8.1
kubectl apply -f common/ns-and-sa.yaml
kubectl apply -f rbac/rbac.yaml
kubectl apply -f common/default-server-secret.yaml
kubectl apply -f common/nginx-config.yaml
kubectl apply -f common/vs-definition.yaml
kubectl apply -f common/vsr-definition.yaml
kubectl apply -f common/ts-definition.yaml
kubectl apply -f common/policy-definition.yaml
kubectl apply -f common/gc-definition.yaml
kubectl apply -f common/global-configuration.yaml
kubectl apply -f daemon-set/nginx-ingress.yaml
kubectl get pods --namespace=nginx-ingress
