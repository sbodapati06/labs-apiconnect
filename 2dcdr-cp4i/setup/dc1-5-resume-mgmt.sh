source global.properties

oc annotate apiconnectcluster $APIC_INSTANCE_NAME apiconnect-operator/dr-data-deletion-confirmation-
oc patch apiconnectcluster $APIC_INSTANCE_NAME --type merge --patch "$(cat dc1-5-resume-mgmt.yaml)"
