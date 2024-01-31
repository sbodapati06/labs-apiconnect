source global.properties

oc login -u kubeadmin -p $PASSIVE_OPENSHIFT_KUBEADMIN_PASSWORD $PASSIVE_OPENSHIFT_API_URL

oc project cp4i-apic
