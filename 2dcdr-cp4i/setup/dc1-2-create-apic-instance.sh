# Author: Sudhakar Bodapati
# Date Created   : 01/12/2024
# Description    : This script will creates a HA Api Connect Active instance on the Primary Data center.
# 
# Prerequisities : a) Run dc1-0-login.sh first
#                  b) Make sure global.properties contains dc1, and dc2 domain values.

# Read global properties - contains dc1 domain and dc2 domain values
source global.properties

APIC_NAMESPACE=$1
APIC_INSTANCE_NAME=$2
HA_PROXY_IP=$3
STORAGE_CLASS_NAME=$4

if [ -z "$1" ]
then 
   APIC_NAMESPACE=cp4i-apic
fi
if [ -z "$2" ]
then 
   APIC_INSTANCE_NAME=apim-demo
fi
if [ -z "$3" ]
then 
   HA_PROXY_IP=52-117-23-234
fi
if [ -z "$3" ]
then 
   STORAGE_CLASS_NAME=ocs-storagecluster-ceph-rbd
fi

echo $APIC_NAMESPACE x $APIC_INSTANCE_NAME x $HA_PROXY_IP x $STORAGE_CLASS_NAME

# make sure the secrets, certificates and issuer are there
echo "..... Secrets ..... "
oc get secrets -n $APIC_NAMESPACE | grep $APIC_INSTANCE_NAME 
echo ""
echo "..... Certificates ..... "
oc get certs -n $APIC_NAMESPACE | grep $APIC_INSTANCE_NAME
echo ""
echo "..... Issuers ..... "
oc get issuer -n $APIC_NAMESPACE | grep $APIC_INSTANCE_NAME
echo ""

# Deploy api connect cluster

echo "..... create api connect cluster ..... "
cat << EOF | oc apply -f -
apiVersion: apiconnect.ibm.com/v1beta1
kind: APIConnectCluster
metadata:
  labels:
    app.kubernetes.io/instance: apiconnect
    app.kubernetes.io/managed-by: ibm-apiconnect
    app.kubernetes.io/name: apiconnect-minimum
  annotations: 
    apiconnect-operator/backups-not-configured: "true"
  name: $APIC_INSTANCE_NAME
  namespace: $APIC_NAMESPACE
spec:
  license:
    accept: true
    license: L-MMBZ-295QZQ
    metric: PROCESSOR_VALUE_UNIT
    use: nonproduction
  profile: n1xc10.m48
  version: 10.0.7.0
  storageClassName: $STORAGE_CLASS_NAME
  management:
    apiManagerEndpoint:
      annotations:
        cert-manager.io/issuer: ${APIC_INSTANCE_NAME}-ingress-issuer
      hosts:
        - name: >-
            ${APIC_INSTANCE_NAME}-mgmt-api-manager.${HA_PROXY_IP}.nip.io
          secretName: ${APIC_INSTANCE_NAME}-mgmt-api-manager
    cloudManagerEndpoint:
      annotations:
        cert-manager.io/issuer: ${APIC_INSTANCE_NAME}-ingress-issuer
      hosts:
        - name: >-
            ${APIC_INSTANCE_NAME}-mgmt-cloudmgr.${HA_PROXY_IP}.nip.io
          secretName: ${APIC_INSTANCE_NAME}-mgmt-cloudmgr
    consumerAPIEndpoint:
      annotations:
        cert-manager.io/issuer: ${APIC_INSTANCE_NAME}-ingress-issuer
      hosts:
        - name: >-
            ${APIC_INSTANCE_NAME}-mgmt-consumer-api.${HA_PROXY_IP}.nip.io
          secretName: ${APIC_INSTANCE_NAME}-mgmt-consumer-api
    platformAPIEndpoint:
      annotations:
        cert-manager.io/issuer: ${APIC_INSTANCE_NAME}-ingress-issuer
      hosts:
        - name: >-
            ${APIC_INSTANCE_NAME}-mgmt-platform-api.${HA_PROXY_IP}.nip.io
          secretName: ${APIC_INSTANCE_NAME}-mgmt-platform-api
    encryptionSecret:
      secretName: mgmt-encryption-key
    multiSiteHA:
      mode: active
      replicationEndpoint:
        annotations:
          cert-manager.io/issuer: ${APIC_INSTANCE_NAME}-ingress-issuer
        hosts:
        - name: mgmt-replication.${ACTIVE_INGRESS_DOMAIN}
          secretName: ${APIC_INSTANCE_NAME}-mgmt-replication-server
      replicationPeerFQDN: mgmt-replication.${PASSIVE_INGRESS_DOMAIN}
      tlsClient:
        secretName: ${APIC_INSTANCE_NAME}-mgmt-replication-client

  portal:
    mtlsValidateClient: true
    portalAdminEndpoint:
      annotations:
        cert-manager.io/issuer: ${APIC_INSTANCE_NAME}-ingress-issuer
      hosts:
      - name: portal-admin.${HA_PROXY_IP}.nip.io
        secretName: portal-admin
    portalUIEndpoint:
      annotations:
        cert-manager.io/issuer: ${APIC_INSTANCE_NAME}-ingress-issuer
      hosts:
      - name: portal-web.${HA_PROXY_IP}.nip.io
        secretName: portal-web
    encryptionSecret:
      secretName: ptl-encryption-key
    multiSiteHA:
      mode: active
      replicationEndpoint:
        annotations:
          cert-manager.io/issuer: ${APIC_INSTANCE_NAME}-ingress-issuer
        hosts:
        - name: ptl-replication.${ACTIVE_INGRESS_DOMAIN}
          secretName: ${APIC_INSTANCE_NAME}-ptl-replication-server
      replicationPeerFQDN: ptl-replication.${PASSIVE_INGRESS_DOMAIN}
      tlsClient:
        secretName: ${APIC_INSTANCE_NAME}-ptl-replication-client

  analytics:
    client:
      endpoint:
        annotations:
          cert-manager.io/issuer: ${APIC_INSTANCE_NAME}-ingress-issuer
        hosts:
          - name: >-
              a7-client.${HA_PROXY_IP}.nip.io
            secretName: ${APIC_INSTANCE_NAME}-a7-client
    ingestion:
      endpoint:
        annotations:
          cert-manager.io/issuer: ${APIC_INSTANCE_NAME}-ingress-issuer
        hosts:
          - name: >-
              a7-ai.${HA_PROXY_IP}.nip.io
            secretName: ${APIC_INSTANCE_NAME}-a7-ai
EOF

sleep 120

oc get mgmt -n $APIC_NAMESPACE

oc get mgmt -n $APIC_NAMESPACE -o jsonpath='{.items[0].status.haStatus}' | jsonlint

echo "Finish"
