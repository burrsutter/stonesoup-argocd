# ACS Demo Clusters


## Setup DOKS clusters

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

Create the clusters, I do this in 4 different terminal sessions, to keep the environments nicely separated

#### Amsterdam

```
export KUBECONFIG=~/xKS/doks-argocd/.kube/config-amsterdam

doctl kubernetes cluster create amsterdam --version 1.24.12-do.0 --region ams3 --node-pool="name=worker-pool;count=2;size=s-4vcpu-8gb"
```

#### Bengaluru

```
export KUBECONFIG=~/xKS/doks-argocd/.kube/config-bengaluru

doctl kubernetes cluster create bengaluru --version 1.24.12-do.0 --region blr1 --node-pool="name=worker-pool;count=2;size=s-4vcpu-8gb"
```

#### New York

```
export KUBECONFIG=~/xKS/doks-argocd/.kube/config-newyork

doctl kubernetes cluster create newyork --version 1.24.12-do.0 --region nyc1 --node-pool="name=worker-pool;count=2;size=s-4vcpu-8gb"
```

#### Toronto

```
export KUBECONFIG=~/xKS/doks-argocd/.kube/config-toronto


doctl kubernetes cluster create toronto --version 1.24.12-do.0 --region tor1 --node-pool="name=worker-pool;count=2;size=s-4vcpu-8gb"
```


Optional: if your KUBECONFIG setting is lost you can overlay the per cluster $KUBECONFIG files

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

## GKE: Frankfurt


```
# Trying to get rid of the following:
# WARNING: the gcp auth plugin is deprecated in v1.22+, unavailable in v1.25+; use gcloud instead.
# To learn more, consult https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke

export PATH=/System/Volumes/Data/opt/homebrew/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin/:$PATH
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
```

```
gcloud container clusters list
```

```
export KUBECONFIG=/Users/burr/xKS/.kubeconfig/frankfurt-config

gcloud container clusters create frankfurt --zone europe-west3-a --num-nodes 2 --machine-type e2-standard-4
```

```
gcloud container clusters list
```

```
NAME       LOCATION        MASTER_VERSION   MASTER_IP      MACHINE_TYPE  NODE_VERSION     NUM_NODES  STATUS
frankfurt  europe-west3-a  1.25.7-gke.1000  34.89.254.242  e2-medium     1.25.7-gke.1000  3          RUNNING
```

Other GKE commands that might be helpful

```
gcloud compute machine-types list --filter="zone:( europe-west3-a )"

gcloud container clusters describe frankfurt --zone europe-west3-a

gcloud container clusters get-credentials frankfurt --zone europe-west3-a

gcloud container clusters resize frankfurt --zone europe-west3-a --node-pool default-pool --num-nodes 3

gcloud container clusters delete frankfurt --zone europe-west3-a
```

## AKS Tokyo


```
export KUBECONFIG=/Users/burr/xKS/.kubeconfig/aks-tokyo-config
```

```
az login

az group create --name myAKSTokyoResourceGroup --location japaneast
```

```
az aks create --resource-group myAKSTokyoResourceGroup --name tokyo -s Standard_DS3_v2 --node-count 2
```

```
az aks get-credentials --resource-group myAKSTokyoResourceGroup --name tokyo --file $KUBECONFIG --overwrite
```


## EKS Cape Town

```
export KUBECONFIG=/Users/burr/xKS/.kubeconfig/capetown-config
```

eksctl install

```
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl
```

```
aws --version
# aws-cli/2.5.3 Python/3.9.12 Darwin/21.4.0 source/arm64 prompt/off

eksctl version
# 0.92.0
```

```
eksctl create cluster \
--name capetown \
--region af-south-1 \
--nodegroup-name myEKSworkers \
--instance-types=m5.xlarge \
--nodes 2 \
--managed
```

```
eksctl utils write-kubeconfig --cluster=capetown --region=af-south-1
aws eks update-kubeconfig --name capetown --region af-south-1
```

Extra EKS commands

```
eksctl delete cluster --region=af-south-1 --name=capetown
```

## ACS Sensor

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

```
helm install -n stackrox --create-namespace stackrox-secured-cluster-services rhacs/secured-cluster-services -f ./bengaluru/values-bengaluru.yaml -f ./bengaluru/bengaluru-cluster-init-bundle.yaml --set imagePullSecrets.username="{registry.redhat.io-user}" --set imagePullSecrets.password="{registry.redhat.io-password}"
```

### New York

```
helm install -n stackrox --create-namespace stackrox-secured-cluster-services rhacs/secured-cluster-services -f ./newyork/values-newyork.yaml -f ./newyork/newyork-cluster-init-bundle.yaml --set imagePullSecrets.username="{registry.redhat.io-user}" --set imagePullSecrets.password="{registry.redhat.io-password}"
```

### Toronto

```
helm install -n stackrox --create-namespace stackrox-secured-cluster-services rhacs/secured-cluster-services -f ./toronto/values-toronto.yaml -f ./toronto/toronto-cluster-init-bundle.yaml --set imagePullSecrets.username="{registry.redhat.io-user}" --set imagePullSecrets.password="{registry.redhat.io-password}"
```

### Frankfurt

```
helm install -n stackrox --create-namespace stackrox-secured-cluster-services rhacs/secured-cluster-services -f ./frankfurt/values-frankfurt.yaml -f ./frankfurt/frankfurt-cluster-init-bundle.yaml --set imagePullSecrets.username="{registry.redhat.io-user}" --set imagePullSecrets.password="{registry.redhat.io-password}"
```

### Tokyo

```
helm install -n stackrox --create-namespace stackrox-secured-cluster-services rhacs/secured-cluster-services -f ./tokyo/values-tokyo.yaml -f ./tokyo/tokyo-cluster-init-bundle.yaml --set imagePullSecrets.username="{registry.redhat.io-user}" --set imagePullSecrets.password="{registry.redhat.io-password}"
```

### Cape Town

```
helm install -n stackrox --create-namespace stackrox-secured-cluster-services rhacs/secured-cluster-services -f ./capetown/values-capetown.yaml -f ./capetown/capetown-cluster-init-bundle.yaml --set imagePullSecrets.username="{registry.redhat.io-user}" --set imagePullSecrets.password="{registry.redhat.io-password}"
```

## Add some ugly apps for ACS to find

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

## Add some pretty apps for ACS to find


```
export KUBECONFIG=~/xKS/.kubeconfig/frankfurt-config
```

```
git clone https://github.com/GoogleCloudPlatform/microservices-demo
cd microservices-demo/
```

```
kubectl apply -f ./release/kubernetes-manifests.yaml
```

```
kubectl get service frontend-external | awk '{print $4}'
```

## GKE App with Ingress

https://cloud.google.com/kubernetes-engine/docs/concepts/ingress

https://cloud.google.com/kubernetes-engine/docs/tutorials/http-balancer

https://cloud.google.com/kubernetes-engine/docs/tutorials/configuring-domain-name-static-ip



```
git clone https://github.com/GoogleCloudPlatform/kubernetes-engine-samples
cd kubernetes-engine-samples/load-balancing
```

```
gcloud compute addresses create web-static-ip --global
gcloud compute addresses describe web-static-ip --global
```

```
kubectl apply -f web-deployment.yaml
kubectl apply -f web-service.yaml
kubectl apply -f basic-ingress-static.yaml
```

```
kubectl get ingress -A
NAMESPACE   NAME            CLASS    HOSTS   ADDRESS   PORTS   AGE
default     basic-ingress   <none>   *                 80      51s
```

```
kubectl get ingress -A
NAMESPACE   NAME            CLASS    HOSTS   ADDRESS          PORTS   AGE
default     basic-ingress   <none>   *       34.120.143.188   80      113s
```

https://cloud.google.com/dns/docs/set-up-dns-records-domain-name#create_a_new_record

Create Cloud DNS Zone

```
gcloud dns --project=ocp42project managed-zones create kinetic-gpc-com --description="" --dns-name="kinetic-gpc.com." --visibility="public" --dnssec-state="off"
```

Create A record

```
gcloud dns --project=ocp42project record-sets create kinetic-gcp.com. --zone="kinetic-gcp-com" --type="A" --ttl="300" --rrdatas="34.120.137.82"
```

Create CNAME

```
gcloud dns --project=ocp42project record-sets create www.kinetic-gcp.com. --zone="kinetic-gcp-com" --type="CNAME" --ttl="300" --rrdatas="web.kinetic-gcp.com."
```

https://support.google.com/domains/answer/3290309


https://www.screencast.com/t/jpauWCn7

https://www.screencast.com/t/f4jxn4rZHJ

```
host kinetic-gcp.com
kinetic-gcp.com has address 34.120.143.188
```

```
curl kinetic-gcp.com
```

```
Hello, world!
Version: 1.0.0
Hostname: web-79df477f97-jhjqq
```


```
kubectl apply -f web-deployment-v2.yaml
kubectl apply -f web-service-v2.yaml
```

```
cat <<EOF | kubectl replace -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: basic-ingress
  annotations:
    kubernetes.io/ingress.global-static-ip-name: "web-static-ip"
spec:
  rules:
  - host: *.kinetic-gcp.com
    http:
      paths:
      - path: /*
        pathType: ImplementationSpecific
        backend:
          service:
            name: web
            port:
              number: 8080
      - path: /v2/*
        pathType: ImplementationSpecific
        backend:
          service:
            name: web2
            port:
              number: 8080
EOF
```

```
curl kinetic-gcp.com
Hello, world!
Version: 1.0.0
Hostname: web-79df477f97-jhjqq
```

```
curl kinetic-gcp.com/v2/
Hello, world!
Version: 2.0.0
Hostname: web2-857c56b696-btxsq
```

## AKS with Ingress

https://portal.azure.com/#view/HubsExtension/BrowseResource/resourceType/Microsoft.DomainRegistration%2Fdomains

```
az group list -o table
Name                                        Location    Status
------------------------------------------  ----------  ---------
NetworkWatcherRG                            uksouth     Succeeded
myAKSTokyoResourceGroup                     japaneast   Succeeded
MC_myAKSTokyoResourceGroup_tokyo_japaneast  japaneast   Succeeded
rg-kinetic-azr.com                          westus      Succeeded
myresourcegroup                             westus      Succeeded
```

```
az network dns record-set a list -g rg-kinetic-azr.com -z kinetic-azr.com
[]
```



## EKS with Ingress

https://us-east-1.console.aws.amazon.com/route53/home#DomainListing:



## Stonesoup Push via ArgoCD



## ArgoCD Pull


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



