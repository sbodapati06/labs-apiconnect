source global.properties

echo "##### data center 2 #####"

echo "\nSuspend management"

dc2-0-login.sh >/dev/null 2>&1
oc patch apiconnectcluster $APIC_INSTANCE_NAME --type merge --patch "$(cat dc2-5-suspend-mgmt.yaml)"


echo "\n\n##### data center 1 #####"

echo "\nResume management"
dc1-0-login.sh >/dev/null 2>&1
dc1-5-resume-mgmt.sh

hastatus.sh

echo "Finish!"
