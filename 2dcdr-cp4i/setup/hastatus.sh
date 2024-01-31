source global.properties

echo "\n########      hastatus     #########"

dc1-0-login.sh >/dev/null 2>&1
echo "\n########  data center 1 #######"

echo "\nManagement"
oc get mgmt -o yaml | grep haMode

if [ "$1" == "--details" ]
then
  echo "\nManagement hastatus ...."
  oc get mgmt -n $APIC_NAMESPACE -o jsonpath='{.items[0].status.haStatus}' | jsonlint
fi

echo "\nPortal"
oc get ptl -o yaml | grep haMode

if [ "$1" == "--details" ]
then
  echo "\n.... Portal hastatus ...."
  oc get mgmt -n $APIC_NAMESPACE -o jsonpath='{.items[0].status.haStatus}' | jsonlint
fi

echo "\n\n########  data center 2 #######"

dc2-0-login.sh >/dev/null 2>&1

echo "\nManagement"
oc get mgmt -o yaml | grep haMode


if [ "$1" == "--details" ]
then
  echo "\n... Management hastatus ...."
  oc get mgmt -n $APIC_NAMESPACE -o jsonpath='{.items[0].status.haStatus}' | jsonlint
fi


echo "\nPortal"
oc get ptl -o yaml | grep haMode

if [ "$1" == "--details" ]
then
  echo "\nPortal hastatus"
  oc get mgmt -n $APIC_NAMESPACE -o jsonpath='{.items[0].status.haStatus}' | jsonlint
fi
