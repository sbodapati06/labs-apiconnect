source global.properties

oc patch apiconnectcluster $APIC_INSTANCE_NAME --type merge --patch "$(cat dc1-5-resume-ptl.yaml)"
