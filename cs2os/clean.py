from marvin import configGenerator
from marvin.cloudstackAPI import *
from optparse import OptionParser
from marvin.codes import (FAILED, SUCCESS)
from marvin.lib.utils import (random_gen)
from marvin.lib.base import Host, Cluster, StoragePool, Volume, Pod, PhysicalNetwork, PublicIpRange, ImageStore, Zone
from marvin.lib.common import list_ssvms
from sys import exit
import os

if __name__ == "__main__":
  print "started"
  parser = OptionParser()
  parser.add_option("-i", "--input", action="store",
                    default=None, dest="input",
                    help="the path \
                    where the json config file generated")
  (options, args) = parser.parse_args()

  if options.input is None:
    print "\n==== For cleaning: Please Specify a " \
          "Valid Input Configuration File ===="
    exit(1)

  if (options.input) and not (os.path.isfile(options.input)):
    print "\n=== Invalid Input Config File Path, Please Check ==="
    exit(1)

  from marvin.marvinLog import MarvinLog
  from marvin.cloudstackTestClient import CSTestClient

  log_obj = MarvinLog("CSLogClean")
  cfg = configGenerator.getSetupConfig(options.input)
  log = cfg.logger
  ret = log_obj.createLogs("Clean_Infra", log)
  if ret != FAILED:
    log_folder_path = log_obj.getLogFolderPath()
    tc_run_logger = log_obj.getLogger()
  else:
    print "\n=== Log Creation Failed. Please Check ==="
    exit(1)

  obj_tc_client = CSTestClient(cfg.mgtSvr[0], cfg.dbSvr,
                               logger=tc_run_logger)
  if obj_tc_client and obj_tc_client.createTestClient() == FAILED:
    print "\n=== TestClient Creation Failed ==="
    exit(1)

  if (options.input) and (os.path.isfile(options.input)):
    apiClient = obj_tc_client.getApiClient()
    tmp_dict = {}

    zones = Zone.list(apiClient)
    if zones:
      for zone in zones:
        print "zone name={}, id={}".format(zone.name, zone.id)
        if zone.allocationstate == 'Enabled':
          print "Disable zone"
          zoneCmd = updateZone.updateZoneCmd()
          zoneCmd.id = zone.id
          zoneCmd.allocationstate = 'Disabled'
          apiClient.updateZone(zoneCmd)

    ssvms = list_ssvms(apiClient)
    if ssvms:
      for ssvm in ssvms:
        print "ssvm name={}, id={}".format(ssvm.name, ssvm.id)
        print "Destroy SSVM"
        cmd = destroySystemVm.destroySystemVmCmd()
        cmd.id = ssvm.id
        apiClient.destroySystemVm(cmd)

    storages = StoragePool.list(apiClient)
    if storages:
      for storage in storages:
        print "storage name={}, id={}".format(storage.name, storage.id)
        if storage.state == 'Maintenance':
          print "delete StoragePool"
          cmd = deleteStoragePool.deleteStoragePoolCmd()
          cmd.id = storage.id
          cmd.forced = 'True'
          apiClient.deleteStoragePool(cmd)
        else:
          print "Delete StoragePool"
          s = StoragePool(tmp_dict)
          s.id = storage.id
          s.forced = 'True'
          s.delete(apiClient)

#    hosts = Host.list(apiClient)
#    if hosts:
#      for host in hosts:
#        print "host name={}, id={}".format(host.name, host.id)
#        if host.type == 'Routing':
#          h = Host(tmp_dict)
#          if host.resourcestate != 'PrepareForMaintenance' \
#              and host.resourcestate != 'Maintenance':
#            print "Maintenance for host"
#            h.enableMaintenance(apiClient, host.id)

    hosts = Host.list(apiClient)
    if hosts:
      for host in hosts:
        print "host name={}, id={}".format(host.name, host.id)
        if host.type == 'Routing':
          if host.resourcestate == 'PrepareForMaintenance' \
              or host.resourcestate == 'Maintenance':
            print "delete host"
            cmd = deleteHost.deleteHostCmd()
            cmd.id = host.id
#            cmd.forced = 'True'
            apiClient.deleteHost(cmd)
          else:
            print "Delete host"
            h = Host(tmp_dict)
#            h.forced = 'True'
            h.id = host.id
            h.delete(apiClient)

    clusters = Cluster.list(apiClient)
    if clusters:
      for cluster in clusters:
        print "cluster name={}, id={}".format(cluster.name, cluster.id)
        if cluster.allocationstate == 'Enabled':
          print "Delete Cluster"
          c = Cluster(tmp_dict)
          c.id = cluster.id
          c.delete(apiClient)

    ipranges = PublicIpRange.list(apiClient)
    if ipranges:
      for iprange in ipranges:
        print "ip range name={}, id={}".format(iprange.name, iprange.id)

    if clusters:
      nets = PhysicalNetwork.list(apiClient)
      if nets:
        for net in nets:
          print "net name={}, id={}".format(net.name, net.id)
          print "Delete PhysicalNetwork"
          n = PhysicalNetwork(tmp_dict)
          n.id = net.id
          n.delete(apiClient)

    pods = Pod.list(apiClient)
    if pods:
      for pod in pods:
        print "pod name={}, id={}".format(pod.name, pod.id)
        print "Delete Pod"
        p = Pod(tmp_dict)
        p.id = pod.id
        p.delete(apiClient)

    img_storages = ImageStore.list(apiClient)
    if img_storages:
      for img_storage in img_storages:
        print "image store name={}, id={}".format(img_storage.name, img_storage.id)
        print "Delete ImageStore"
        i = ImageStore(tmp_dict)
        i.id = img_storage.id
        i.delete(apiClient)

    print "Delete Zone"
    z = Zone(tmp_dict)
    z.id = zone.id
    z.delete(apiClient)

  exit(0)
