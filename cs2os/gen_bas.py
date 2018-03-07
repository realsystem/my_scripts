import random
import marvin
from marvin.configGenerator import *
 
def describeResources():
    zs = cloudstackConfiguration()
 
    z = zone()
    z.dns1 = '172.18.80.136'
    z.internaldns1 = '172.18.80.136'
    z.name = 'zone1'
    z.networktype = 'Basic'
#disable security groups for advanced
    z.securitygroupenabled = 'True'

    sgprovider = provider()
    sgprovider.broadcastdomainrange = 'Pod'
    sgprovider.name = 'SecurityGroupProvider'

    pn = physicalNetwork()
    pn.name = "test-network"
    pn.traffictypes = [trafficType("Guest"), trafficType("Management")]
    pn.providers.append(sgprovider)
    z.physical_networks.append(pn)
 
    p = pod()
    p.name = 'POD0'
    p.gateway = '172.16.66.1'
    p.startip =  '172.16.66.180'
    p.endip =  '172.16.66.189'
    p.netmask = '255.255.255.0'
 
    ip = iprange()
    ip.gateway = '172.16.66.1'
    ip.startip = '172.16.66.80'
    ip.endip = '172.16.66.89'
    ip.netmask = '255.255.255.0'
    p.guestIpRanges.append(ip)
 
    c = cluster()
    c.clustername = 'C0'
    c.hypervisor = 'KVM'
    c.clustertype = 'CloudManaged'
 
    h = host()
    h.username = 'root'
    h.password = 'swordfish'
    h.url = 'http://172.16.66.198'
    c.hosts.append(h)
 
    ps = primaryStorage()
    ps.name = 'PS0'
    ps.url = 'nfs://172.16.66.199:/mnt/usr/export/primary'
    ps.provider = 'nfs'
    c.primaryStorages.append(ps)
 
    p.clusters.append(c)
    z.pods.append(p)
 
    secondary = secondaryStorage()
    secondary.url = 'nfs://172.16.66.199:/mnt/usr/export/secondary'
    secondary.provider = 'nfs'
    z.secondaryStorages.append(secondary)
 
    '''Add zone'''
    zs.zones.append(z)
 
    '''Add mgt server'''
    mgt = managementServer()
    mgt.mgtSvrIp = '172.16.66.199'
    zs.mgtSvr.append(mgt)
 
    '''Add a database'''
    db = dbServer()
    db.dbSvr = '172.16.66.199'
    db.user = 'cloud'
    db.passwd = 'swordfish'
    zs.dbSvr = db
 
    '''Add some configuration'''
    [zs.globalConfig.append(cfg) for cfg in getGlobalSettings()]
 
    ''''add loggers'''
    testLogger = logger()
    testLogger.logFolderPath = '/tmp/tmp/'
    zs.logger = testLogger
    return zs
 
def getGlobalSettings():
   globals = { "storage.cleanup.interval" : "300",
               "account.cleanup.interval" : "60",
               "secstorage.allowed.internal.sites" : "172.16.66.199/24",
            }
 
   for k, v in globals.iteritems():
        cfg = configuration()
        cfg.name = k
        cfg.value = v
        yield cfg
 
if __name__ == '__main__':
    config = describeResources()
    generate_setup_config(config, 'advanced_cloud.cfg')
