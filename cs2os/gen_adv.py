import random
import marvin
from marvin.configGenerator import *
 
def describeResources():
    zs = cloudstackConfiguration()
 
    z = zone()
    z.dns1 = '172.18.80.136'
    z.internaldns1 = '172.18.80.136'
    z.name = 'zone1'
    z.networktype = 'Advanced'
#    z.guestcidraddress = '172.18.66.0/24'
    z.vlan = "10-1000"
#    z.securitygroupenabled = "true"

    pn1 = physicalNetwork()
    pn1.name = "test-network1"
    pn1.traffictypes = [trafficType("Public"), trafficType("Guest"), trafficType("Management")]
#    pn1.tags=["cloudbr0"]
#    pn1.isolationmethods = ["VLAN"]
    z.physical_networks.append(pn1)
 
#    pn2 = physicalNetwork()
#    pn2.name = "test-network2"
#    pn2.traffictypes = [trafficType("Management")]
#    pn2.tags=["cloudbr1"]
#    pn2.isolationmethods = ["VLAN"]
#    z.physical_networks.append(pn2)
 
#    sgprovider = provider()
#    sgprovider.broadcastdomainrange = 'ZONE'
#    sgprovider.name = 'SecurityGroupProvider'

#    pn.providers.append(sgprovider)

    p = pod()
    p.name = 'POD0'
    p.gateway = '172.16.66.1'
    p.startip =  '172.16.66.80'
    p.endip =  '172.16.66.89'
    p.netmask = '255.255.255.0'
 
    v = iprange()
    v.gateway = '192.168.0.1'
    v.startip = '192.168.0.20'
    v.endip = '192.168.0.100'
    v.netmask = '255.255.255.0'
    v.vlan = '200'
    z.ipranges.append(v)
 
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
               "expunge.delay": "60",
               "expunge.interval": "60",
               "expunge.workers": "3",
            }
 
   for k, v in globals.iteritems():
        cfg = configuration()
        cfg.name = k
        cfg.value = v
        yield cfg
 
if __name__ == '__main__':
    config = describeResources()
    generate_setup_config(config, 'advanced_cloud.cfg')
