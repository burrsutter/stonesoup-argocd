#/bin/bash

# Run this script like so:
# API_URL="(url to API server)" ./create-managed-env-secret.sh
#
# the API_URL value should look like this:
# - "https://a0d62111a7aa94d108e5458dd50f8e29-70cfcfe9ca1f783c.elb.us-east-1.amazonaws.com:6443"
# - It should NOT look like this: "https://console-openshift-console.apps.76c87b434dc56eb9f57e.hypershift.aws-2.ci.openshift.org"
#
# The script will create a ServiceAccount/ClusterRole/ClusterRoleBinding/Secret, extract the token from the Secret, 
# and output either a Secret, or just the kubeconfig for use with RHTAP.

# set -x

echo "Create ServiceAccount, Secret, ClusterRole/Binding"

# Create ServiceAccount, Secret, ClusterRole/Binding
cat <<EOF | kubectl apply -f -

# Create a new ServiceAccount for use by Argo CD
kind: ServiceAccount
apiVersion: v1
metadata:
  name: my-service-account
  namespace: kube-system
---

# Create a new 'service-account-token' Secret, which the Kubenetes cluster should fill in with token information.
apiVersion: v1
kind: Secret
metadata:
  name: my-service-account-secret
  namespace: kube-system  
  annotations:
    kubernetes.io/service-account.name: my-service-acccount

type: kubernetes.io/service-account-token

---

# Full access ClusterRole

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: my-cluster-role
rules:
- apiGroups:
  - '*'
  resources:
  - '*'
  verbs:
  - '*'
- nonResourceURLs:
  - '*'
  verbs:
  - '*'

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: my-cluster-role-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: my-cluster-role
subjects:
- kind: ServiceAccount
  name: my-service-account
  namespace: kube-system

EOF

# Look for a Secret with type kubernetes.io/service-account-token in kube-system.
# Extract the token field, containing the bearer token.
while true
do


	TOKEN_SECRET_NAME=`kubectl get secret -n kube-system -o=jsonpath='{.items[?(@.metadata.annotations.kubernetes\.io/service-account\.name=="my-service-account")].metadata.name}' | tr -s " " | sed -e "s/ /\\n/g" | grep "token"`

	SECRET_TOKEN=`kubectl get secret/$TOKEN_SECRET_NAME -n kube-system -o json -o jsonpath='{.data.token}' | base64 -d`

	if [ -n "$SECRET_TOKEN" ]; then
		break
	fi

	sleep 1
done

echo Token is $SECRET_TOKEN



# uncomment this, and comment out the following line, to kubectl apply, rather than outputting it to the screen
# cat <<EOF | kubectl apply -f -

printf "\n\n\nSecret:"

cat << EOF
apiVersion: v1
kind: Secret
metadata:
  name: my-managed-environment-secret
type: managed-gitops.redhat.com/managed-environment
stringData:
  # Note: This would be base 64 when stored on the cluster
  kubeconfig: |
    apiVersion: v1
    clusters:
    - cluster:
        insecure-skip-tls-verify: true
        server: $API_URL
        # for example:
        # server: https://api.my-cluster.dev.rhcloud.com:6443
      name: cluster-name
    contexts:
    - context:
        cluster: cluster-name
        namespace: default
        user: cluster-user
      name: my-current-context
    current-context: my-current-context
    kind: Config
    preferences: {}
    users:
    - name: cluster-user
      user:
        token: sha256~$SECRET_TOKEN
EOF


printf "\n\n\nOr, just the kubeconfig:"

cat << EOF

apiVersion: v1
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: $API_URL
    # for example:
    # server: https://api.my-cluster.dev.rhcloud.com:6443
  name: cluster-name
contexts:
- context:
    cluster: cluster-name
    namespace: default
    user: cluster-user
  name: my-current-context
current-context: my-current-context
kind: Config
preferences: {}
users:
- name: cluster-user
  user:
    token: $SECRET_TOKEN
EOF
