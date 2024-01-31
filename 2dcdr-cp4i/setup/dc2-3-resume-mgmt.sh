source global.properties

# Remove annotation
oc annotate apiconnectcluster $APIC_INSTANCE_NAME apiconnect-operator/dr-data-deletion-confirmation-
# enable multiSiteHA
oc patch apiconnectcluster $APIC_INSTANCE_NAME --type merge --patch "$(cat dc2-3-resume-mgmt.yaml)"
