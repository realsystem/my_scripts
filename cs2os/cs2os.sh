#!/bin/sh

#define common
tmp_dir=/tmp/images
project=proj1
vm_name=vm1

#define DST
dst_user=root
dst_password=swordfish
dst_server=172.16.66.67
DST_SSH_CMD="ssh -o StrictHostKeychecking=no ${dst_user}@${dst_server}"
DST_ENV=`cat << EOF
declare -x OS_AUTH="http://node-6:35357/v2.0";
declare -x OS_AUTH_URL="http://node-6:35357/v2.0";
declare -x OS_PASSWORD="admin";
declare -x OS_TENANT_NAME="admin";
declare -x OS_USERNAME="admin";
EOF`
DST_SSH="${DST_SSH_CMD} ${DST_ENV}"

#define SRC
SRC_CLI="/usr/local/bin/cloudmonkey"
src_user=root
src_password=swordfish
src_server=172.16.66.199
src_db_name=cloud
SRC_SSH_CMD="sshpass -p ${src_password} ssh -o StrictHostKeychecking=no ${src_user}@${src_server}"
SRC_CMD="export TERM=vt100 && ${SRC_CLI}"
SRC_SSH="${SRC_SSH_CMD} ${SRC_CMD}"

#define functions
#arg1 - project name
#arg2 - project description
function CREATE_TENANT {
  ${DST_SSH} keystone tenant-create --name ${1} --description ${2}
}

#arg1 - project name
function DELETE_TENANT {
  ${DST_SSH} keystone tenant-delete ${1}
}

#arg1 - name
function GET_TENANT_ID {
  ${DST_SSH} keystone tenant-list | grep ${1} | cut -d ' ' -f 2
}

#arg1 - user name
#arg2 - tenant name
#arg3 - user password
function CREATE_USER {
  ${DST_SSH} keystone user-create --name ${1} --tenant ${2} --pass ${3}
}

#arg1 - user name
function DELETE_USER {
  ${DST_SSH} keystone user-delete ${1}
}

#arg1 - user name
#arg2 - role name
#arg3 - tenant name
function ADD_ROLE_TO_USER {
  ${DST_SSH} keystone user-role-add --user ${1} --role ${2} --tenant ${3}
}

#arg1 - user name
#arg2 - role name
#arg3 - tenant name
function DELETE_ROLE_FROM_USER {
  ${DST_SSH} keystone user-role-remove --user ${1} --role ${2} --tenant ${3}
}

#arg1 - name
#arg2 - file
#arg3 - disk format
#arg4 - container format
#arg5 - is public
function CREATE_IMAGE {
  ${DST_SSH} glance image-create --name ${1} --file ${2} --disk-format ${3} --container-format ${4} --is-public ${5} --progress
}

#arg1 - name
function DELETE_IMAGE {
  ${DST_SSH} glance image-delete ${1}
}

#arg1 - name
function GET_IMAGE_ID {
  ${DST_SSH} glance image-list | grep ${1} | cut -d ' ' -f 2
}

function GET_IMAGE_LIST {
  ${DST_SSH} glance image-list | grep bare | cut -d ' ' -f 2
}

#arg1 - project name
#arg2 - volume name
#arg3 - image src id
#arg4 - size(GB)
function CREATE_VOLUME {
  ${DST_SSH} cinder --os-tenant-name ${1} create --display-name ${2} --image-id ${3} ${4}
}

#arg1 - name
function DELETE_VOLUME {
  ${DST_SSH} cinder delete ${1}
}

function GET_VOLUME_LIST {
  ${DST_SSH} nova volume-list --all-tenants | grep None | cut -d ' ' -f 2
}

#arg1 - name
#arg2 - id
#arg3 - memory
#arg4 - disk size
#arg5 - CPU number
function CREATE_FLAVOR {
  ${DST_SSH} nova flavor-create ${1} ${2} ${3} ${4} ${5}
}

#arg1 - name
function DELETE_FLAVOR {
  ${DST_SSH} nova flavor-delete ${1}
}

function GET_FLAVOR_LIST {
  ${DST_SSH} nova flavor-list | grep True | cut -d ' ' -f 2
}

#arg1 - tenant name
#arg2 - VM name
#arg3 - flavor name/id
#arg4 - image name/id
#arg5 - network ID
#arg6 - IPv4 fixed address
function CREATE_VM {
  if [ -n "$5" ]; then
    ${DST_SSH} nova --os-tenant-name ${1} boot --flavor ${3} --image ${4} --nic net-id=${5} ${2}
  else
    ${DST_SSH} nova --os-tenant-name ${1} boot --flavor ${3} --image ${4} --nic ${2}
  fi
}

#arg1 - VM name
function DELETE_VM {
  ${DST_SSH} nova delete ${1}
}

function GET_VM_LIST {
  ${DST_SSH} nova list --all-tenants | grep -v ID | grep -v + | cut -d ' ' -f 2
}

#arg1 - tenant name
#arg2 - network name
function CREATE_IN_NET {
  ${DST_SSH} neutron net-create --tenant-id ${1} ${2}
}

#arg1 - tenant name
#arg2 - network name
function CREATE_OUT_NET {
  ${DST_SSH} neutron net-create --tenant-id ${1} ${2} --router:external True --provider:network_type flat --provider:physical_network physnet2
}

#arg1 - tenant id
function DELETE_NET {
  ${DST_SSH} neutron net-delete ${1}
}

function GET_NET_LIST {
  ${DST_SSH} nova net-list | grep -v ID | grep -v + | cut -d ' ' -f 2
}

#arg1 - name
function GET_NET_ID {
  ${DST_SSH} nova net-list | grep ${1} | grep -v ID | grep -v + | cut -d ' ' -f 2
}

#arg1 - network name
#arg2 - subnetwork name
#arg3 - disable-dhcp or enable-dhcp
#arg4 - gateway
#arg5 - netmask
#arg6 - float IP start
#arg7 - float IP end
function CREATE_SUBNET {
  if [ -n "$7" ]; then
    ${DST_SSH} neutron subnet-create --tenant-id ${1} ${2} --name ${3} --allocation-pool start=${7},end=${8} --${4} --gateway ${5} ${6}
  else
    ${DST_SSH} neutron subnet-create --tenant-id ${1} ${2} --name ${3} --${4} --gateway ${5} ${6}
  fi
}

#arg1 - network name
function DELETE_SUBNET {
  ${DST_SSH} neutron subnet-delete ${1}
}

#arg1 - network name
#arg2 - max count
function GET_SUBNET_LIST {
  ${DST_SSH} neutron net-show ${1} | grep -A ${2} subnets | grep -v tenant_id | grep -v + | cut -d '|' -f 3 | sed 's/^[ \t]*//'
}

#arg1 - tenant ID
#arg2 - router name
#arg3 - external network name
#arg4 - subnet network name
function CREATE_ROUTER {
  ${DST_SSH} neutron router-create --tenant-id ${1} ${2}
  ${DST_SSH} neutron router-gateway-set ${2} ${3}
  ${DST_SSH} neutron router-interface-add ${2} ${4}
}

#arg1 - tenant ID
function DELETE_ROUTER {
  ${DST_SSH} neutron router-gateway-clear ${1}
  for n in `GET_NET_LIST`; do
    for s in `GET_SUBNET_LIST ${n} 3`; do
      ${DST_SSH} neutron router-interface-delete ${1} ${s}
    done
  done
  ${DST_SSH} neutron router-delete ${1}
}

function GET_ROUTER_LIST {
  ${DST_SSH} neutron router-list -F id | grep -v + | grep -v id | cut -d '|' -f 2 | sed 's/^[ \t]*//'
}

#arg1 - router name
function GET_ROUTER_IFACES_LIST {
  ${DST_SSH} neutron router-show -F id | grep -v + | grep -v id | cut -d '|' -f 2 | sed 's/^[ \t]*//'
}

#arg1 - port ID
#arg2 - VM ID
function ATTACH_PORT {
  ${DST_SSH} nova interface-attach --port-id ${1} ${2}
}

#arg1 - network name
function CREATE_PORT {
  ${DST_SSH} neutron port-create ${1}
}

#arg1 - port name
function DELETE_PORT {
  ${DST_SSH} neutron port-delete ${1}
}

function GET_PORT_LIST {
  ${DST_SSH} neutron port-list -F id | grep -v + | grep -v id | cut -d '|' -f 2 | sed 's/^[ \t]*//'
}

#arg1 - subnet name
function GET_PORT {
  for x in `${DST_SSH} neutron port-list | grep ${1} | cut -d '|' -f 2 | sed 's/^[ \t]*//'`; do
    output=`${DST_SSH} neutron port-show ${x} -F device_owner | grep compute`
    if [ -n "$output" ]; then echo $x; exit; fi
  done
}

#arg1 - tenant ID
#arg2 - network name
function FLOAT_IP_CREATE {
  ${DST_SSH} neutron floatingip-create --tenant-id ${1} ${2}
}

function GET_FLOAT_LIST {
  ${DST_SSH} neutron floatingip-list | grep -v + | grep -v id | cut -d '|' -f 2 | sed 's/^[ \t]*//'
}

#arg1 - float IP ID
#arg2 - port ID
function FLOAT_IP_ASS {
  ${DST_SSH} neutron floatingip-associate ${1} ${2}
}

#arg1 - float IP ID
function FLOAT_IP_DEL {
  ${DST_SSH} neutron floatingip-delete {1}
}

#arg1 - tenant name
function GET_SECGRP {
  ${DST_SSH} nova --os-tenant-id ${1} secgroup-list | grep def | cut -d '|' -f 2 | sed 's/^[ \t]*//'
}

#arg1 - group ID
function ADD_RULE {
  ${DST_SSH} neutron security-group-rule-create --protocol icmp --direction ingress --remote-ip-prefix 0.0.0.0/0 ${1}
  ${DST_SSH} neutron security-group-rule-create --protocol tcp --port-range-min 22 --port-range-max 22 --direction ingress ${1}
}

function mask2cidr {
    nbits=0
    IFS=.
    for dec in $1 ; do
        case $dec in
            255) let nbits+=8;;
            254) let nbits+=7;;
            252) let nbits+=6;;
            248) let nbits+=5;;
            240) let nbits+=4;;
            224) let nbits+=3;;
            192) let nbits+=2;;
            128) let nbits+=1;;
            0);;
            *) echo "Error: $dec is not recognised"; exit 1
        esac
    done
    echo "$nbits"
}

#arg1 - filtering on monkey side
#arg1 - filtering on monkey side
#arg2 - filtering on shell side
function PARSE {
  echo "filter=${1} | grep ${2} | awk -F ': ' '{print \$2}' | sed 's/^[ \t]*//' | sed 's/\"//g'"
}

#arg1 - what to select
#arg2 - table name
#arg3 - known field
#arg4 - known value
function DB_SELECT {
  mysql -h${src_server} -u${src_user} -p${src_password} -e "SELECT ${1} FROM ${src_db_name}.${2} WHERE ${3}='${4}'" | grep -v ${1}
}

#arg1 - template or ISO ID
function DB_GET_TMPL_PATH {
  db_tmpl_id=`DB_SELECT id vm_template uuid ${1}`
  db_inst_path=`DB_SELECT install_path template_store_ref template_id ${db_tmpl_id}`
  db_sec_stor_par_id=`DB_SELECT local_path template_store_ref template_id ${db_tmpl_id} | awk -F '/' '{print $4}'`
  db_sec_stor_uuid=`DB_SELECT uuid image_store parent ${db_sec_stor_par_id}`
  TMP=`PARSE protocol protocol`
  sec_storage_type=`${SRC_SSH} list imagestores id=${db_sec_stor_uuid} ${TMP}`
  TMP=`PARSE url url`
  sec_storage_url=`${SRC_SSH} list imagestores id=${db_sec_stor_uuid} ${TMP}`
  echo "${sec_storage_url}/${db_inst_path}"
}

echo Getting IDs
TMP=`PARSE id id`
proj_id=`${SRC_SSH} list projects name=${project} ${TMP}`
echo "Project ID = ${proj_id}"

TMP=`PARSE id id`
vm_id=`${SRC_SSH} list virtualmachines projectid=${proj_id} name=${vm_name} ${TMP}`
echo "VM ID = ${vm_id}"

echo Common
TMP=`PARSE project project`
proj_name=`${SRC_SSH} list virtualmachines id=${vm_id} ${TMP}`
if [ -z "${proj_name}" ]; then proj_name="admin"; fi
echo "Project name = ${proj_name}"

TMP=`PARSE displaytext displaytext`
proj_desc=`${SRC_SSH} list projects id=${proj_id} ${TMP}`
if [ -z "$proj_desc" ]; then proj_desc=${proj_name}; fi
echo "Project description = ${proj_desc}"

TMP=`PARSE account account`
proj_user=`${SRC_SSH} list projects id=${proj_id} ${TMP}`
echo "Project user = ${proj_user}"

TMP=`PARSE hypervisor hypervisor`
hv=`${SRC_SSH} list virtualmachines id=${vm_id} ${TMP}`
echo "Hypervisor = ${hv}"

TMP=`PARSE storageid storageid`
prim_storage_id=`${SRC_SSH} list volumes virtualmachineid=${vm_id} projectid=${proj_id} ${TMP}`
echo "Primary storage ID = ${prim_storage_id}"

TMP=`PARSE type type`
prim_storage_type=`${SRC_SSH} list storagepools id=${prim_storage_id} ${TMP}`
echo "Primary storage type = ${prim_storage_type}"

TMP=`PARSE ipaddress ipaddress`
prim_storage_ip=`${SRC_SSH} list storagepools id=${prim_storage_id} ${TMP}`
echo "Primary storage IP = ${prim_storage_ip}"

TMP=`PARSE path path`
prim_storage_path=`${SRC_SSH} list storagepools id=${prim_storage_id} ${TMP}`
echo "Primary storage path = ${prim_storage_path}"

echo Volume
TMP=`PARSE id id`
root_volume_id=`${SRC_SSH} list volumes virtualmachineid=${vm_id} projectid=${proj_id} type=ROOT ${TMP}`
echo "ROOT Volume ID = ${root_volume_id}"

TMP=`PARSE name name`
root_volume_name=`${SRC_SSH} list volumes virtualmachineid=${vm_id} projectid=${proj_id} type=ROOT ${TMP}`
echo "ROOT Volume name = ${root_volume_name}"

root_volume_path="${dst_user}@${prim_storage_ip}:${prim_storage_path}/${root_volume_id}"
echo "ROOT Full path: ${root_volume_path}"

TMP=`PARSE id id`
data_volume_id=`${SRC_SSH} list volumes virtualmachineid=${vm_id} projectid=${proj_id} type=DATADISK ${TMP}`
echo "Data Volume ID = ${data_volume_id}"

TMP=`PARSE name name`
data_volume_name=`${SRC_SSH} list volumes virtualmachineid=${vm_id} projectid=${proj_id} type=DATADISK ${TMP}`
echo "Data Volume name = ${data_volume_name}"

primary_full_path="${dst_user}@${prim_storage_ip}:${prim_storage_path}/${data_volume_id}"
echo "Primary Full path: ${primary_full_path}"

echo VM Template
TMP=`PARSE templateid templateid`
template_id=`${SRC_SSH} list virtualmachines id=${vm_id} ${TMP}`
echo "Template ID = ${template_id}"

TMP=`PARSE format format`
template_format=`${SRC_SSH} list templates templatefilter=all id=${template_id} ${TMP} | tr [:upper:] [:lower:]`
echo "Template format = ${template_format}"

TMP=`PARSE templatename templatename`
template_name=`${SRC_SSH} list virtualmachines id=${vm_id} ${TMP}`
echo "Template name = ${template_name}"

#first copy of template is located on secondary storage
#template_path=`DB_GET_TMPL_PATH ${template_id} | sed "s/nfs:\/\//${src_user}@/" | sed "s/\//\//"`
#echo "Template path: ${template_path}"

#second copy of template is located on primary storage
template_path=${primary_full_path}/${template_id}
echo "Template path: ${template_path}"

echo Mounted ISO
TMP=`PARSE isoid isoid`
iso_id=`${SRC_SSH} list virtualmachines id=${vm_id} ${TMP}`
echo "ISO ID = ${iso_id}"

TMP=`PARSE isoname isoname`
iso_name=`${SRC_SSH} list virtualmachines id=${vm_id} ${TMP}`
echo "ISO name = ${iso_name}"

iso_path=`DB_GET_TMPL_PATH ${iso_id} | sed "s/nfs:\/\//${src_user}@/" | sed "s/\//\//"`
echo "ISO path: ${iso_path}"

echo Flavor
TMP=`PARSE serviceofferingname serviceofferingname`
flav_name=`${SRC_SSH} list virtualmachines id=${vm_id} ${TMP} | sed "s/ /./"`
echo "Flavor = ${flav_name}"

TMP=`PARSE serviceofferingid id`
servoffer_id=`${SRC_SSH} list virtualmachines id=${vm_id} ${TMP}`
echo "Service offering ID = ${servoffer_id}"

TMP=`PARSE cpunumber cpunumber`
cpu_num=`${SRC_SSH} list serviceofferings id=${servoffer_id} ${TMP}`
echo "CPU number = ${cpu_num}"

TMP=`PARSE memory memory`
memory=`${SRC_SSH} list serviceofferings id=${servoffer_id} ${TMP}`
echo "Memory = ${memory}"

TMP=`PARSE diskofferingid id`
diskoffer_id=`${SRC_SSH} list virtualmachines id=${vm_id} ${TMP}`
if [ -n "$diskoffer_id" ]; then
  echo "Disk offering ID = ${diskoffer_id}"
  TMP=`PARSE disksize disksize`
  disk_size=`${SRC_SSH} list diskofferings id=${diskoffer_id} ${TMP}`
else
  TMP=`PARSE size size`
  disk_size=`${SRC_SSH} list templates templatefilter=all id=${template_id} ${TMP}`
  let "disk_size=$disk_size/1024/1024/1024"
fi
echo "Disk size = ${disk_size}"

echo Network
TMP=`PARSE networkid networkid`
net_id=`${SRC_SSH} list nics virtualmachineid=${vm_id} ${TMP}`
echo "Network ID = ${net_id}"

TMP=`PARSE name name`
net_name=`${SRC_SSH} list networks id=${net_id} ${TMP}`
echo "Network name = ${net_name}"

TMP=`PARSE gateway gateway`
gw=`${SRC_SSH} list nics virtualmachineid=${vm_id} ${TMP}`
echo "Gateway = ${gw}"

TMP=`PARSE netmask netmask`
netmask=`${SRC_SSH} list nics virtualmachineid=${vm_id} ${TMP}`
echo "Netmask = ${netmask}"

TMP=`PARSE ipaddress ipaddress`
ip_addr=`${SRC_SSH} list nics virtualmachineid=${vm_id} ${TMP}`
echo "IP address = ${ip_addr}"

cidr=`echo ${ip_addr} | sed 's/\.[0-9]*$/.0/'`/`mask2cidr ${netmask}`
echo "CIDR = ${cidr}"

TMP=`PARSE zoneid zoneid`
zone_id=`${SRC_SSH} list virtualmachines id=${vm_id} ${TMP}`
echo "Zone ID = ${zone_id}"

TMP=`PARSE networktype networktype`
net_type=`${SRC_SSH} list zones id=${zone_id} ${TMP}`
echo "Network type = ${net_type}"

if [ "$net_type" == "Basic" ]; then
  TMP=`PARSE networkid networkid`
  tmp_net_id=`${SRC_SSH} list vlanipranges ${TMP}`
  echo "Network ID in vlanipranges = ${tmp_net_id}"

  if [ "$tmp_net_id" == "$net_id" ]; then
    TMP=`PARSE startip startip`
    guest_start_ip=`${SRC_SSH} list vlanipranges ${TMP}`
    echo "Guest start IP = ${guest_start_ip}"

    TMP=`PARSE endip endip`
    guest_end_ip=`${SRC_SSH} list vlanipranges ${TMP}`
    echo "Guest end IP = ${guest_end_ip}"
  fi
  TMP=`PARSE id id`
  router_id=`${SRC_SSH} list routers account=system ${TMP}`
  echo "Router ID = ${router_id}"

  TMP=`PARSE name name`
  router_name=`${SRC_SSH} list routers account=system ${TMP}`
  echo "Router name = ${router_name}"

  TMP=`PARSE guestnetworkid guestnetworkid`
  router_guestnetworkid=`${SRC_SSH} list routers account=system ${TMP}`
  echo "Router guest network ID = ${router_guestnetworkid}"
fi
echo Stop VM on SRC
${SRC_SSH} stop virtualmachine id=${vm_id}

tenant_id=`GET_TENANT_ID ${proj_name}`
echo "Old tenant ID = ${tenant_id}"

echo Switch to the destination environment
echo Cleaning environment
for x in `GET_FLOAT_LIST`; do echo "Delete float IP $x"; FLOAT_IP_DEL $x; done
for x in `GET_VM_LIST`; do echo "Delete VM $x"; DELETE_VM $x; done
for x in `GET_FLAVOR_LIST`; do echo "Delete flavor $x"; DELETE_FLAVOR $x; done
for x in `GET_VOLUME_LIST`; do echo "Delete volume $x"; DELETE_VOLUME $x; done
for x in `GET_IMAGE_LIST`; do echo "Delete image $x"; DELETE_IMAGE $x; done
for x in `GET_ROUTER_LIST`; do echo "Delete router $x"; DELETE_ROUTER $x; done
for x in `GET_PORT_LIST`; do echo "Delete port $x"; DELETE_PORT $x; done
for x in `GET_NET_LIST`
do
#  echo "Delete subnet in network $x"
#  for y in `GET_SUBNET_LIST ${x}`; do echo "Delete subnet $y"; DELETE_SUBNET $y; done
  echo "Delete network $x"
  DELETE_NET $x
done

DELETE_TENANT ${proj_name}
rm -rf ${tmp_dir}
mkdir ${tmp_dir}

echo Creating tenant
CREATE_TENANT ${proj_name} ${proj_desc}

tenant_id=`GET_TENANT_ID ${proj_name}`
echo "Tenant ID = ${tenant_id}"

echo Creating user
echo CREATE_USER ${proj_user}

role_name=admin

echo Adding role
ADD_ROLE_TO_USER ${proj_user} ${role_name} ${proj_name}

echo Create flavor
CREATE_FLAVOR ${flav_name} auto ${memory} 0 ${cpu_num}
#CREATE_FLAVOR ${flav_name} auto ${memory} ${disk_size} ${cpu_num}

echo Create network
CREATE_IN_NET ${tenant_id} ${net_name}_in
dst_subnetin_id=`CREATE_SUBNET ${tenant_id} ${net_name}_in ${net_name}_inSubnet enable-dhcp 192.168.0.1 192.168.0/24 | grep ' id' | cut -d '|' -f 3 | sed 's/^[ \t]*//'`
echo "Subnet IN ID ${dst_subnetin_id}"
CREATE_OUT_NET ${tenant_id} ${net_name}_out
CREATE_SUBNET ${tenant_id} ${net_name}_out ${net_name}_outSubnet disable-dhcp ${gw} ${cidr} ${guest_start_ip} ${guest_end_ip}

dst_netin_id=`GET_NET_ID ${net_name}_in`
echo "New network in ID = ${dst_netin_id}"

dst_netout_id=`GET_NET_ID ${net_name}_out`
echo "New network out ID = ${dst_netout_id}"

if [ -n "$dst_netout_id" ]; then
  if [ "$router_guestnetworkid" == "$net_id" ]; then
    CREATE_ROUTER ${tenant_id} ${router_name} ${net_name}_out ${net_name}_inSubnet
  fi
fi

if [ -n "$iso_name" ]; then
  echo Adding ISO images
  sshpass -p ${src_password} scp ${iso_path} ${tmp_dir}/${iso_name}
  sshpass -p ${dst_password} scp ${tmp_dir}/${iso_name} ${dst_user}@${dst_server}:/tmp/
  CREATE_IMAGE ${iso_name} /tmp/${iso_name} iso bare True
fi

if [ -n "$template_name" ]; then
  echo Adding template images
  sshpass -p ${src_password} scp ${template_path} ${tmp_dir}/${template_name}
  sshpass -p ${dst_password} scp ${tmp_dir}/${template_name} ${dst_user}@${dst_server}:/tmp/
  CREATE_IMAGE ${template_name} /tmp/${template_name} ${template_format} bare True
  template_image_id=`GET_IMAGE_ID ${template_name}`
  echo "Template image ID = ${template_image_id}"
fi

if [ -n "$data_volume_name" ]; then
  echo Adding images for data volume
  sshpass -p ${src_password} scp ${primary_full_path} ${tmp_dir}/${data_volume_name}
  sshpass -p ${dst_password} scp ${tmp_dir}/${data_volume_name} ${dst_user}@${dst_server}:/tmp/
  CREATE_IMAGE ${data_volume_name} /tmp/${data_volume_name} qcow2 bare True
  echo Create data volume
  data_image_id=`GET_IMAGE_ID ${data_volume_name}`
  echo "Data image ID = ${data_image_id}"
  CREATE_VOLUME ${proj_name} ${data_volume_name} ${data_image_id} ${disk_size}
fi

echo Create instance
if [ -n "$dst_netin_id" ]; then
  dst_vm_id=`CREATE_VM ${proj_name} ${vm_name} ${flav_name} ${template_image_id} ${dst_netin_id} | grep ' id' | cut -d '|' -f 3 | sed 's/^[ \t]*//'`
  echo "VM ID ${dst_vm_id}"
else
  CREATE_VM ${proj_name} ${vm_name} ${flav_name} ${template_image_id}
fi

out_port=`GET_PORT ${dst_subnetin_id}`
echo "Port ID for out ${out_port}"
FLOAT_IP_CREATE ${tenant_id} ${net_name}_out
out_float_ip=`GET_FLOAT_LIST`
echo "Floating IP ID ${out_float_ip}"
FLOAT_IP_ASS ${out_float_ip} ${out_port}
sec_group_id=`GET_SECGRP ${tenant_id}`
echo "Security group default ID ${sec_group_id}"
ADD_RULE ${sec_group_id}
