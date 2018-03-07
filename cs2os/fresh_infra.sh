srv=172.16.66.199
srv_host=172.16.66.198
pass=swordfish
python clean.py -i advanced_cloud.cfg
sshpass -p $pass ssh root@${srv} "rm -rf /mnt/usr/export/{primary,secondary}/* && service cloudstack-management stop"
sshpass -p $pass ssh root@${srv_host} "service libvirt-bin restart && service cloudstack-agent restart"
mysqladmin -h${srv} -ucloud -p$pass -f drop cloud
sshpass -p $pass ssh root@${srv} "cloudstack-setup-databases cloud:$pass@localhost --deploy-as=root:$pass"
sshpass -p $pass ssh root@${srv} "/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt -m /mnt/usr/export/secondary -f /root/systemvm64template-4.4.1-7-kvm.qcow2.bz2 -h kvm -F"
sshpass -p $pass ssh root@${srv} "service cloudstack-management start && export TERM=vt100 && /usr/local/bin/cloudmonkey list users"
sshpass -p $pass ssh root@${srv} "export TERM=vt100 && /usr/local/bin/cloudmonkey api updateConfiguration name=integration.api.port value=8096"
sshpass -p $pass ssh root@${srv} "service cloudstack-management restart && export TERM=vt100 && /usr/local/bin/cloudmonkey list users"
exit
python gen_bas.py
python /usr/local/lib/python2.7/dist-packages/marvin/deployDataCenter.py -i advanced_cloud.cfg
#python upload_templates.py -c advanced_cloud.cfg -i http://cdimage.debian.org/debian-cd/8.0.0/amd64/iso-cd/debian-8.0.0-amd64-netinst.iso
python upload_templates.py -c advanced_cloud.cfg -t http://172.18.66.24/debian_img.qcow2
