source global.properties

echo "######  Data center 1 ######"

dc1-0-login.sh >/dev/null 2>&1

echo "\nSuspend Management"
oc patch apiconnectcluster $APIC_INSTANCE_NAME --type merge --patch "$(cat dc1-3-suspend-mgmt.yaml)"

echo "\n\n######  Data center 2 ######"

echo "\nResume Management\n"

dc2-0-login.sh >/dev/null 2>&1
dc2-3-resume-mgmt.sh

hastatus.sh

echo "Finish!"
