#!/bin/sh

project="proj1"
vm_name="vm1"
template="deb"
service_offer="Small Instance"
disk_offer="Small"
zone_name="zone1"
SRC_CLI="/usr/local/bin/cloudmonkey"
src_user=root
src_password=swordfish
src_server=172.16.66.199
SRC_SSH_CMD="sshpass -p ${src_password} ssh -o StrictHostKeychecking=no ${src_user}@${src_server}"
SRC_CMD="export TERM=vt100 && ${SRC_CLI}"
SRC_SSH="${SRC_SSH_CMD} ${SRC_CMD}"

#arg1 - filtering on monkey side
#arg2 - filtering on shell side
function PARSE {
  echo "filter=${1} | grep ${2} | cut -d ':' -f 2 | sed 's/^[ \t]*//'"
}

TMP=`PARSE id id`
project_id=`${SRC_SSH} list projects name=${project} ${TMP}`
echo "Project ID = ${project_id}"

TMP=`PARSE id id`
vm_id=`${SRC_SSH} list virtualmachines name=${vm_name} ${TMP}`
echo "VM ID = ${vm_id}"

echo Cleaning infra
if [ -n "$vm_id" ]; then
  ${SRC_SSH} destroy virtualmachine id=${vm_id} expunge=true
fi
if [ -n "$project_id" ]; then
  ${SRC_SSH} delete project id=${project_id}
fi

echo Creating project
${SRC_SSH} create project name=${project} displaytext=${project}

TMP=`PARSE id id`
project_id=`${SRC_SSH} list projects name=${project} ${TMP}`
echo "New project ID = ${project_id}"

echo Getting IDs
TMP=`PARSE id id`
zone_id=`${SRC_SSH} list zones name=${zone_name} ${TMP}`
echo "Zone ID = ${zone_id}"

TMP=`PARSE id id`
template_id=`${SRC_SSH} list templates templatefilter=all name=${template} ${TMP}`
echo "Template ID = ${template_id}"

TMP=`PARSE id id`
service_offer_id=`${SRC_SSH} list serviceofferings name=\'${service_offer}\' ${TMP}`
echo "Service offering ID = ${service_offer_id}"

#TMP=`PARSE id id`
#disk_offer_id=`${SRC_SSH} list diskofferings name=${disk_offer} ${TMP}`
#echo "Disk offering ID = ${disk_offer_id}"

echo Deploy VM
${SRC_SSH} deploy virtualmachine zoneid=${zone_id} serviceofferingid=${service_offer_id} templateid=${template_id} name=${vm_name} projectid=${project_id}
