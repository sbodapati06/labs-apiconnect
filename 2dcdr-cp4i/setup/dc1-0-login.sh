source global.properties

oc login -u kubeadmin -p $ACTIVE_OPENSHIFT_KUBEADMIN_PASSWORD $ACTIVE_OPENSHIFT_API_URL

oc project cp4i-apic
