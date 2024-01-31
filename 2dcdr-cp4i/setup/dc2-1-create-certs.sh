# Author: Sudhakar Bodapati
# Date Created: 01/12/2024
# Description: This script creates certificates for the DR API Connect instance

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

# dc1-ca-issuer.secreat.yaml is from the active site
oc apply -f dc1-ca-issuer-secret.yaml -n $APIC_NAMESPACE

oc get secret -n $APIC_NAMESPACE | grep $APIC_INSTANCE_NAME

# Create the ingress issuer

cat << EOF | oc apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: ${APIC_INSTANCE_NAME}-ingress-issuer
  namespace: ${APIC_NAMESPACE}
spec:
  ca:
    secretName: ${APIC_INSTANCE_NAME}-ingress-ca
EOF


oc get issuer -n $APIC_NAMESPACE | grep $APIC_INSTANCE_NAME

# Create the encyrption key secrets from the Active setup
oc create secret generic mgmt-encryption-key --from-file=encryption_secret.bin=dc1-mgmt-enc-key.txt -n $APIC_NAMESPACE
oc create secret generic ptl-encryption-key --from-file=encryption_secret=dc1-ptl-enc-key.txt -n $APIC_NAMESPACE
oc get secrets -n $APIC_NAMESPACE | grep $APIC_INSTANCE_NAME


# Create the TLS Client replication certificate for the Management 

cat << EOF | oc apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${APIC_INSTANCE_NAME}-mgmt-replication-client
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


# Create the TLS Client replication certificate for the Portal

cat << EOF | oc apply -f -
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

oc get certs -n $APIC_NAMESPACE | grep ${APIC_INSTANCE_NAME}

echo "Finish"
