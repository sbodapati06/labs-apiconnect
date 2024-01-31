source global.properties

echo "\n##### Data Center 1 #####"

echo "\nSuspend Portal"
dc1-0-login.sh >/dev/null 2>&1
oc patch apiconnectcluster $APIC_INSTANCE_NAME --type merge --patch "$(cat dc1-4-suspend-ptl.yaml)"

echo "\nn##### Data Center 2 #####'"
echo "\nResume Portal"

dc2-0-login.sh >/dev/null 2>&1
dc2-4-resume-ptl.sh

hastatus.sh

echo "Finish!"
