# ArgoCD Pull from Stonesoup into ROSA


Install Gitops and Pipelines Operators

```
oc adm policy add-cluster-role-to-user cluster-admin -z openshift-gitops-argocd-application-controller -n openshift-gitops
```

```
oc new-project bsutter-tenant
 
oc apply -n openshift-gitops -f https://raw.githubusercontent.com/burrsutter/stonesoup-argocd/main/bsutter-boot/Application-openshift.yaml
```

```
oc new-project burrzinga-tenant

oc apply -n openshift-gitops -f https://raw.githubusercontent.com/burrsutter/stonesoup-argocd/main/burrzinga-accounting/Application-openshift.yaml
```



