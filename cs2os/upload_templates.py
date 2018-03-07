from marvin import configGenerator
from marvin.cloudstackAPI import *
from optparse import OptionParser
from marvin.codes import (FAILED, SUCCESS)
from marvin.lib.utils import (random_gen)
from marvin.lib.base import Iso, Zone, Template
from sys import exit
import os

if __name__ == "__main__":
  print "started"
  parser = OptionParser()
  parser.add_option("-c", "--input_config", action="store",
                    default=None, dest="input",
                    help="the path \
                    where the json config file generated")
  parser.add_option("-i", "--upload_iso", action="store",
                    default=None, dest="upload_iso",
                    help="the HTTP path \
                    where the ISO is located")
  parser.add_option("-t", "--upload_tmpl", action="store",
                    default=None, dest="upload_tmpl",
                    help="the HTTP path \
                    where the template is located")
  (options, args) = parser.parse_args()

  if options.input is None:
    print "\n==== For uploading file: Please Specify a " \
          "Valid Input Configuration File ===="
    exit(1)

  if (options.upload_iso is None) and (options.upload_tmpl is None):
    print "\n==== For uploading file: Please Specify a " \
          "HTTP path for file ===="
    exit(1)

  if (options.input) and not (os.path.isfile(options.input)):
    print "\n=== Invalid Input Config File Path, Please Check ==="
    exit(1)

  from marvin.marvinLog import MarvinLog
  from marvin.cloudstackTestClient import CSTestClient

  log_obj = MarvinLog("CSLogTemplates")
  cfg = configGenerator.getSetupConfig(options.input)
  log = cfg.logger
  ret = log_obj.createLogs("UploadTemplates", log)
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
    zones = Zone.list(apiClient)
    if zones:
      for zone in zones:
        print "zone name={}, id={}".format(zone.name, zone.id)
        if zone.allocationstate == 'Enabled':
          services = {}
          services["displaytext"] = "Debian"
          services["name"] = "deb"
          if options.upload_tmpl is not None:
            services["hypervisor"] = "KVM"
            services["format"] = "QCOW2"
            services["url"] = options.upload_tmpl
          if options.upload_iso is not None:
            services["url"] = options.upload_iso
          services["ostype"] = "Debian GNU/Linux 7(64-bit)"
          services["zoneid"] = zone.id
          tmp_dict = {}
          if options.upload_tmpl is not None:
            my_templ = Template(tmp_dict)
            if my_templ.register(apiClient, services) == FAILED:
              print "Uploading template failed"
              tc_run_logger.debug("\n=== Uploading template failed ===");
              exit(1)
          if options.upload_iso is not None:
            my_templ = Iso(tmp_dict)
            if my_templ.create(apiClient, services) == FAILED:
              print "Uploading template failed"
              tc_run_logger.debug("\n=== Uploading template failed ===");
              exit(1)
        else:
          print "Zone is not ready"
    else:
      print "No zones"
  exit(0)
