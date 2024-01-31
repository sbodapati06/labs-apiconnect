# Author: Sudhakar Bodapati
# Date Created: 01/12/2024
# Description: This script creates certificates for the Primary API Connect instance

source global.properties

APIC_NAMESPACE=$1
APIC_INSTANCE_NAME=$2

if [ -z "$1" ]
then
   APIC_NAMESPACE=cp4i-apic
fi
if [ -z "$2" ]
then
   APIC_INSTANCE_NAME=apim-demo
fi

echo $APIC_NAMESPACE 
echo $APIC_INSTANCE_NAME

# management encryption key
cat /dev/urandom | head -c63 | base64  > dc1-mgmt-enc-key.txt
oc delete secret mgmt-encryption-key -n $APIC_NAMESPACE
oc create secret generic mgmt-encryption-key --from-file=encryption_secret.bin=dc1-mgmt-enc-key.txt -n $APIC_NAMESPACE
oc get secrets -n $APIC_NAMESPACE | grep mgmt-encryption-key

# Portal encryption key
cat /dev/urandom | head -c63 | base64  > dc1-ptl-enc-key.txt
oc delete secret ptl-encryption-key -n $APIC_NAMESPACE
oc create secret generic ptl-encryption-key --from-file=encryption_secret=dc1-ptl-enc-key.txt -n $APIC_NAMESPACE
oc get secrets -n $APIC_NAMESPACE | grep ptl-encryption-key


# Create a self-signed issuer
oc delete issuer ${APIC_INSTANCE_NAME}-self-signed -n ${APIC_NAMESPACE} 
cat << EOF | oc apply -n $APIC_NAMESPACE -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: ${APIC_INSTANCE_NAME}-self-signed
  namespace: ${APIC_NAMESPACE}
spec:
  selfSigned: {}
EOF

oc get issuer -n $APIC_NAMESPACE

# Create ingress-ca certificate

oc delete Certificate ${APIC_INSTANCE_NAME}-ingress-ca -n $APIC_NAMESPACE

cat << EOF | oc apply -n $APIC_NAMESPACE -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${APIC_INSTANCE_NAME}-ingress-ca
  namespace: $APIC_NAMESPACE
spec:
  commonName: ingress-ca
  duration: 87600h0m0s
  isCA: true
  issuerRef:
    kind: Issuer
    name: ${APIC_INSTANCE_NAME}-self-signed
  renewBefore: 720h0m0s
  privateKey:
    rotationPolicy: Always
  secretName: ${APIC_INSTANCE_NAME}-ingress-ca
EOF

oc get cert -n $APIC_NAMESPACE

# Create the ingress issuer
oc delete issuer ${APIC_INSTANCE_NAME}-ingress-issuer -n $APIC_NAMESPACE

cat << EOF | oc apply -n $APIC_NAMESPACE -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: ${APIC_INSTANCE_NAME}-ingress-issuer
  namespace: $APIC_NAMESPACE
spec:
  ca:
    secretName: ${APIC_INSTANCE_NAME}-ingress-ca
EOF

oc get issuer -n $APIC_NAMESPACE


######  Create the TLS client replication certificates for management and portal

## Management Replication Client Certificate

oc delete Certificate ${APIC_INSTANCE_NAME}-replication-client -n ${APIC_NAMESPACE}

cat << EOF | oc apply -n $APIC_NAMESPACE -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${APIC_INSTANCE_NAME}-replication-client
  namespace: ${APIC_NAMESPACE}
spec:
  commonName: ${APIC_INSTANCE_NAME}-mgmt-replication-client
  duration: 17520h0m0s
  issuerRef:
    kind: Issuer
    name: ${APIC_INSTANCE_NAME}-ingress-issuer
  renewBefore: 720h0m0s
  privateKey:
    rotationPolicy: Always
  secretName: ${APIC_INSTANCE_NAME}-mgmt-replication-client
EOF


## Portal Replication Client Certificate

oc delete Certificate ${APIC_INSTANCE_NAME}-ptl-replication-client -n ${APIC_NAMESPACE}

cat << EOF | oc apply -n $APIC_NAMESPACE -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${APIC_INSTANCE_NAME}-ptl-replication-client
  namespace: ${APIC_NAMESPACE}
spec:
  commonName: ${APIC_INSTANCE_NAME}-ptl-replication-client
  duration: 17520h0m0s
  issuerRef:
    kind: Issuer
    name: ${APIC_INSTANCE_NAME}-ingress-issuer
  renewBefore: 720h0m0s
  privateKey:
    rotationPolicy: Always
  secretName: ${APIC_INSTANCE_NAME}-ptl-replication-client
EOF

oc get certs -n $APIC_NAMESPACE

# Extract ingress-ca secret
oc get secret ${APIC_INSTANCE_NAME}-ingress-ca -o yaml -n $APIC_NAMESPACE  > dc1-ca-issuer-secret-org.yaml

yq eval 'del(.metadta.uid, .metadata.creationTimestamp, .metadata.resourceVersion)' dc1-ca-issuer-secret-org.yaml > dc1-ca-issuer-secret.yaml


# Cleanup
rm dc1-ca-issuer-secret-org.yaml

echo "Finish"
