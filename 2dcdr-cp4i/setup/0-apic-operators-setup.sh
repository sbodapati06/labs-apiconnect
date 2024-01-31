# Brand new setup

source global.properties

storage_default.sh

# PRE REQ: 
#     Make sure the default storageclass is set to block storage 


# install Catalog sources for cert-manager-redhat, foundational0services, platform navigator, datapower, apiconnect
# create platform navigator

CP4I_NAMESPACE=$1
APIC_NAMESPACE=$2

### Default CP4I_NAMESPACE
if [ -z "$1" ]
then
   CP4I_NAMESPACE=cp4i
fi

### Default APIC_NAMESPACE
if [ -z "$2" ]
then
   APIC_NAMESPACE=cp4i-apic
fi

# Install the cert manager operator

oc apply -f 0-cert-manager-rh.yaml


# Foundational services catalog source & operator

export OPERATOR_PACKAGE_NAME=ibm-cp-common-services && export OPERATOR_VERSION=4.3.1 && export ARCH=amd64
oc ibm-pak get ${OPERATOR_PACKAGE_NAME} --version ${OPERATOR_VERSION}
oc ibm-pak generate mirror-manifests ${OPERATOR_PACKAGE_NAME} icr.io --version ${OPERATOR_VERSION}
oc apply -f ~/.ibm-pak/data/mirror/${OPERATOR_PACKAGE_NAME}/${OPERATOR_VERSION}/catalog-sources.yaml


# Platform navigator catalog source & operator

export OPERATOR_PACKAGE_NAME=ibm-integration-platform-navigator && export OPERATOR_VERSION=7.2.0 && export ARCH=amd64
oc ibm-pak get ${OPERATOR_PACKAGE_NAME} --version ${OPERATOR_VERSION}
oc ibm-pak generate mirror-manifests ${OPERATOR_PACKAGE_NAME} icr.io --version ${OPERATOR_VERSION}
oc apply -f ~/.ibm-pak/data/mirror/${OPERATOR_PACKAGE_NAME}/${OPERATOR_VERSION}/catalog-sources.yaml


# Data Power catalog source & operator

export OPERATOR_PACKAGE_NAME=ibm-datapower-operator && export OPERATOR_VERSION=1.9.0
oc ibm-pak get ${OPERATOR_PACKAGE_NAME} --version ${OPERATOR_VERSION}
oc ibm-pak generate mirror-manifests ${OPERATOR_PACKAGE_NAME} icr.io --version ${OPERATOR_VERSION}
oc apply -f ~/.ibm-pak/data/mirror/${OPERATOR_PACKAGE_NAME}/${OPERATOR_VERSION}/catalog-sources-linux-amd64.yaml

# API Connect catalog source & operator

export OPERATOR_PACKAGE_NAME=ibm-apiconnect && export OPERATOR_VERSION=5.1.0
oc ibm-pak get ${OPERATOR_PACKAGE_NAME} --version ${OPERATOR_VERSION}
oc ibm-pak generate mirror-manifests ${OPERATOR_PACKAGE_NAME} icr.io --version ${OPERATOR_VERSION}
oc apply -f ~/.ibm-pak/data/mirror/${OPERATOR_PACKAGE_NAME}/${OPERATOR_VERSION}/catalog-sources.yaml


# Create ibm-common-services project
cat << EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ibm-common-services 
  annotations:
    openshift.io/node-selector: ""
  labels:
    openshift.io/cluster-monitoring: "true"
EOF

# Create cp4i project
cat << EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ${CP4I_NAMESPACE}
  annotations:
    openshift.io/node-selector: ""
  labels:
    openshift.io/cluster-monitoring: "true"
EOF

# Create cp4i-apic project
cat << EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: ${APIC_NAMESPACE}
  annotations:
    openshift.io/node-selector: ""
  labels:
    openshift.io/cluster-monitoring: "true"
EOF

sleep 60

# Operator Subscription - Foundational services
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-common-service-operator
  namespace: openshift-operators
spec:
  channel: v4.3
  installPlanApproval: Automatic
  name: ibm-common-service-operator
  source: opencloud-operators
  sourceNamespace: openshift-marketplace
EOF

# Operator Subscription - API Connect
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  labels:
    operators.coreos.com/ibm-apiconnect.openshift-operators: ""
  name: ibm-apiconnect
  namespace: openshift-operators
spec:
  channel: v5.1
  installPlanApproval: Automatic
  name: ibm-apiconnect
  source: ibm-apiconnect-catalog
  sourceNamespace: openshift-marketplace
  startingCSV: ibm-apiconnect.v5.1.0
EOF


# Operator Subscription - PN
cat << EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ibm-integration-platform-navigator
  namespace: openshift-operators
spec:
  channel: v7.2
  name: ibm-integration-platform-navigator
  source: ibm-integration-platform-navigator-catalog
  sourceNamespace: openshift-marketplace
EOF

# ibm-entitlement-key

oc create secret docker-registry ibm-entitlement-key --docker-username=cp --docker-password=${IBM_ENTITLEMENT_KEY} --docker-server=cp.icr.io --namespace=${CP4I_NAMESPACE}
oc create secret docker-registry ibm-entitlement-key --docker-username=cp --docker-password=${IBM_ENTITLEMENT_KEY} --docker-server=cp.icr.io --namespace=${APIC_NAMESPACE}

sleep 120

# Create platform navigator instance

cat << EOF | oc apply -f -
apiVersion: integration.ibm.com/v1beta1
kind: PlatformNavigator
metadata:
  name: cp4i-navigator
  namespace: ${CP4I_NAMESPACE}
spec:
  license:
    accept: true
    license: L-VTPK-22YZPK
  replicas: 3
  version: 2023.4.1
EOF

echo "finish"
