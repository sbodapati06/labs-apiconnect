source global.properties

echo "\n##### data center 2 #####"

echo "\nSuspend portal "

dc2-0-login.sh >/dev/null 2>&1
oc annotate apiconnectcluster $APIC_INSTANCE_NAME -n $APIC_NAMESPACE apiconnect-operator/dr-data-deletion-confirmation-

oc patch apiconnectcluster $APIC_INSTANCE_NAME -n $APIC_NAMESPACE --type merge --patch "$(cat dc2-5-suspend-ptl.yaml)"


echo "\n\n##### data center 1 #####"

echo "\nResume portal "
dc1-0-login.sh >/dev/null 2>&1

oc annotate apiconnectcluster $APIC_INSTANCE_NAME -n $APIC_NAMESPACE apiconnect-operator/dr-data-deletion-confirmation-
dc1-5-resume-ptl.sh

hastatus.sh

echo "Finish!"
