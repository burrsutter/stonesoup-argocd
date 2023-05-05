# Setup DOKS clusters

This will require a token

https://cloud.digitalocean.com/account/api/tokens


Do you have any clusters up?

```
doctl kubernetes cluster list
```

Do you have any load-balancers up?  These are a result from using Service type Load-Balancer

```
doctl compute load-balancer list
```

```
doctl kubernetes options sizes
```

```
export KUBE_EDITOR="code -w"
export PATH=~/devnation/bin:$PATH
```

Create a place for the KUBECONFIGs.  I like keeping my clusters separated via unique KUBECONFIGs

```
mkdir .kube
```

```
export KUBECONFIG=~/xKS/doks-argocd/.kube/config-amsterdam
```

```
export KUBECONFIG=~/xKS/doks-argocd/.kube/config-bengaluru
```

```
export KUBECONFIG=~/xKS/doks-argocd/.kube/config-newyork
```

```
export KUBECONFIG=~/xKS/doks-argocd/.kube/config-toronto
```

Create the clusters, I do this in 4 different terminal sessions, to keep the environments nicely separated

```
doctl kubernetes cluster create amsterdam --version 1.24.12-do.0 --region ams3 --node-pool="name=worker-pool;count=2;size=s-4vcpu-8gb"
```

```
doctl kubernetes cluster create bengaluru --version 1.24.12-do.0 --region blr1 --node-pool="name=worker-pool;count=2;size=s-4vcpu-8gb"
```

```
doctl kubernetes cluster create newyork --version 1.24.12-do.0 --region nyc1 --node-pool="name=worker-pool;count=2;size=s-4vcpu-8gb"
```

```
doctl kubernetes cluster create toronto --version 1.24.12-do.0 --region tor1 --node-pool="name=worker-pool;count=2;size=s-4vcpu-8gb"
```


If needed, overlay the per cluster $KUBECONFIG files

```
doctl k8s cluster kubeconfig show amsterdam >> $KUBECONFIG
```

```
doctl k8s cluster kubeconfig show bengaluru >> $KUBECONFIG
```

```
doctl k8s cluster kubeconfig show newyork >> $KUBECONFIG
```

```
doctl k8s cluster kubeconfig show toronto >> $KUBECONFIG
```

```
doctl kubernetes cluster list
```


```
ID                                      Name         Region    Version         Auto Upgrade    Status     Node Pools
b5a0165b-5841-4466-b5d1-dd38a01be681    toronto      tor1      1.24.12-do.0    false           running    worker-pool
5cdf6045-3d79-4390-a088-19aa1e92ccaf    newyork      nyc1      1.24.12-do.0    false           running    worker-pool
634cd022-5d0b-40d2-ba70-8189574e5575    bengaluru    blr1      1.24.12-do.0    false           running    worker-pool
75ecb161-232c-489a-9799-1092d840bbab    amsterdam    ams3      1.24.12-do.0    false           running    worker-pool
```

# ACS Sensor

### Add these clusters to ACS

Related to this video

https://youtu.be/za_bAAtZanU

Figure out your registry.redhat.io user and password 

```
docker login registry.redhat.io
```

```
helm repo add rhacs https://mirror.openshift.com/pub/rhacs/charts/
```

### Amsterdam
```
helm install -n stackrox --create-namespace stackrox-secured-cluster-services rhacs/secured-cluster-services -f ./amsterdam/values-amsterdam.yaml -f ./amsterdam/amsterdam-cluster-init-bundle.yaml --set imagePullSecrets.username="{registry.redhat.io-user}" --set imagePullSecrets.password="{registry.redhat.io-password}"
```

### Bengaluru
helm install -n stackrox --create-namespace stackrox-secured-cluster-services rhacs/secured-cluster-services -f ./bengaluru/values-bengaluru.yaml -f ./bengaluru/bengaluru-cluster-init-bundle.yaml --set imagePullSecrets.username="{registry.redhat.io-user}" --set imagePullSecrets.password="{registry.redhat.io-password}"

### New York
helm install -n stackrox --create-namespace stackrox-secured-cluster-services rhacs/secured-cluster-services -f ./newyork/values-newyork.yaml -f ./newyork/newyork-cluster-init-bundle.yaml --set imagePullSecrets.username="{registry.redhat.io-user}" --set imagePullSecrets.password="{registry.redhat.io-password}"

### Toronto
helm install -n stackrox --create-namespace stackrox-secured-cluster-services rhacs/secured-cluster-services -f ./toronto/values-toronto.yaml -f ./toronto/toronto-cluster-init-bundle.yaml --set imagePullSecrets.username="{registry.redhat.io-user}" --set imagePullSecrets.password="{registry.redhat.io-password}"


# Add some ugly apps for ACS to find

```
kubectl create namespace shelly
kubectl create deployment shocked --image=vulnerables/cve-2014-6271 -n shelly
```

```
kubectl create namespace tango
kubectl create deployment samba --image=vulnerables/cve-2017-7494 -n tango
```

```
kubectl create namespace finance
kubectl apply -f https://raw.githubusercontent.com/burrsutter/acm-argocd-acs/main/acs-hello/minerd-deployment.yaml
```

```
kubectl create namespace devops
kubectl apply -f https://raw.githubusercontent.com/burrsutter/acm-argocd-acs/main/acs-hello/log4shellapp.yaml
```


# ArgoCD Push from Stonesoup 


Download argocd binary

https://github.com/argoproj/argo-cd/releases

Important env vars to configure, making sure kubectl and argocd are in the PATH

```
export KUBE_EDITOR="code -w"
export PATH=~/devnation/bin:$PATH
```


Discover API_URL

```
TOR_API_URL=$(doctl kubernetes cluster get toronto -o json | jq -r '.[].endpoint')
echo $TOR_API_URL
```

```
API_URL=$TOR_API_URL .create-secrets.sh
```

```
kubectl create namespace burrzinga-tenant
```

https://www.screencast.com/t/LmlUBHIiDG


# ArgoCD Pull

```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

Wait for the external IP to be populated

```
watch kubectl get services argocd-server -n argocd
```

```
NAME            TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)                      AGE
argocd-server   LoadBalancer   10.245.5.37   68.183.245.216   80:31643/TCP,443:30114/TCP   5m41s
```

Get the default password and IP address

```
ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

ARGOCD_IP=$(kubectl -n argocd get service argocd-server -o jsonpath="{.status.loadBalancer.ingress[0].ip}"):80

echo $ARGOCD_IP

echo $ARGOCD_PASS
```

Open the browser to the correct address

```
open http://$ARGOCD_IP
```

Also login via the argocd CLI

```
argocd login --insecure --grpc-web $ARGOCD_IP  --username admin --password $ARGOCD_PASS
```

```
argocd cluster list
```

```
SERVER                          NAME        VERSION  STATUS   MESSAGE                                                  PROJECT
https://kubernetes.default.svc  in-cluster           Unknown  Cluster has no applications and is not being monitored.
```

Because of the .tekton directory in the Stonesoup gitops repo create some additional CRDs

????

```
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
```  

Create an Application

```
kubectl apply -f burrzinga-boot/Application.yaml
```


![Burrzinga Boot Syncing](images/burrzinga-boot-syncing.png)


```
oc new-project bsutter-tenant
 
oc apply -n openshift-gitops -f https://raw.githubusercontent.com/burrsutter/stonesoup-argocd/main/bsutter-boot/Application-openshift.yaml
```

```
doctl k8s cluster delete toronto
doctl k8s cluster delete bengaluru
doctl k8s cluster delete amsterdam
doctl k8s cluster delete newyork
```



