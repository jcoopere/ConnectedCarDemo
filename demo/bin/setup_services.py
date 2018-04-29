#!/usr/local/bin/python2.7
# encoding: utf-8

import sys
import time
import os

from cm_api.api_client import ApiResource
from cm_api.endpoints.services import ApiService
from cm_api.endpoints.parcels import ApiParcel

__all__ = []
__version__ = 0.1
__date__ = '2016-10-13'
__updated__ = '2016-10-13'

DEBUG = 1
TESTRUN = 0
PROFILE = 0

class CLIError(Exception):
    '''Generic exception to raise and log different fatal errors.'''
    def __init__(self, msg):
        super(CLIError).__init__(type(self))
        self.msg = "E: %s" % msg
    def __str__(self):
        return self.msg
    def __unicode__(self):
        return self.msg

def upgrade_hive(cluster):
  # Upgrade Hive Metastore
  hive_service = cluster.get_service("HIVE-1")
  assert isinstance(hive_service, ApiService)
  if hive_service.serviceState != 'STOPPED':
      hive_service.stop().wait()
  hive_service.upgrade_hive_metastore().wait()
  hive_service.start().wait()

def deploy_arcadia_parcel(cluster):
  arcadia_parcel = next(p for p in cluster.get_all_parcels() if p.product == 'ARCADIAENTERPRISE')
  if arcadia_parcel.stage == 'ACTIVATED':
    print 'Arcadia Parcel already activated.'
    return
  arcadia_parcel.start_download()
  time.sleep(1)
  while True:
    arcadia_parcel = next(p for p in cluster.get_all_parcels() if p.product == 'ARCADIAENTERPRISE')
    if (arcadia_parcel.stage == 'DOWNLOADED') or (arcadia_parcel.stage == 'DISTRIBUTED'):
      break
    time.sleep(5)

  print "Done downloading Arcadia Parcel"

  arcadia_parcel.start_distribution()
  time.sleep(1)
  while True:
    arcadia_parcel = next(p for p in cluster.get_all_parcels() if p.product == 'ARCADIAENTERPRISE')
    if arcadia_parcel.stage == 'DISTRIBUTED':
      break
    time.sleep(5) 

  print "Done distributing Arcadia Parcel"
  arcadia_parcel.activate().wait()

  #cluster.stop().wait()
  #cluster.start().wait()

def deploy_streamsets_parcel(cluster):
  streamsets_parcel = next(p for p in cluster.get_all_parcels() if p.product == 'STREAMSETS_DATACOLLECTOR')
  if streamsets_parcel.stage == 'ACTIVATED':
    print 'StreamSets Parcel already activated.'
    return
  streamsets_parcel.start_download()
  time.sleep(1)
  while True:
    streamsets_parcel = next(p for p in cluster.get_all_parcels() if p.product == 'STREAMSETS_DATACOLLECTOR')
    if (streamsets_parcel.stage == 'DOWNLOADED') or (streamsets_parcel.stage == 'DISTRIBUTED'):
      break
    time.sleep(5)

  print "Done downloading StreamSets parcel!"

  streamsets_parcel.start_distribution()
  time.sleep(1)
  while True:
    streamsets_parcel = next(p for p in cluster.get_all_parcels() if p.product == 'STREAMSETS_DATACOLLECTOR')
    if streamsets_parcel.stage == 'DISTRIBUTED':
      break
    time.sleep(5) 

  print "Done distributing StreamSets parcel!"
  streamsets_parcel.activate().wait()

  #cluster.stop().wait()
  #cluster.start().wait()

def add_arcadia_service(cluster, arcengine_hosts, arcviz_host, arcengine_cat_host, arcengine_ss_host):
  service = cluster.create_service("Arcadia", "ARCADIAENTERPRISE")
  service.update_config({"hive_service":"HIVE-1"})
  service.update_config({"hdfs_service":"HDFS-1"})
  service.update_config({"impala_service":"IMPALA-1"})
  service.update_config({"yarn_service":"YARN-1"})
  assert isinstance(service, ApiService)
  #cluster.auto_configure()
  #service.create_role("Engine", "ARCENGINE", arcengine_host.split(",")) # ARCENGINE runs on multiple hosts, so split CSV and pass array of hosts
  service.create_role_config_group("Arcenginegroup1", "arcenginegroup1", "ARCENGINE")
  arcengine_hosts_arr = arcengine_hosts.split(",")
  i = 0
  for host in arcengine_hosts_arr:
    i += 1
    service.create_role("Engine-" + str(i), "ARCENGINE", host)
  service.create_role("Viz", "ARCVIZ", arcviz_host)
  service.create_role("Catalog", "ARCENGINE_CATALOG", arcengine_cat_host)
  service.create_role("StateStore", "ARCENGINE_STATESTORE", arcengine_ss_host)
  service.role_command_by_name("InitArcviz", "Viz")
  time.sleep(10)
  service.restart().wait()
  print "Started Arcadia Enterprise Service Successfully"

def add_streamsets_service(cluster, datacollector_host):
  service = cluster.create_service("STREAMSETS-1", "STREAMSETS")
  assert isinstance(service, ApiService)
  #cluster.auto_configure() # auto_configure() does not work with custom CSDs...will cause a strange behavior with Kudu installed
  service.create_role("DataCollector", "DATACOLLECTOR", datacollector_host)
  time.sleep(10)
  service.restart().wait()
  print "Started StreamSets service Successfully"

def main(argv=None): # IGNORE:C0111

  program_name = os.path.basename(sys.argv[0])
  cm_host = str(sys.argv[1])
  arcengine_hosts = str(sys.argv[2]) # Should be a CSV list of target arcengine hosts
  arcviz_host = str(sys.argv[3])
  arcengine_cat_host = str(sys.argv[4])
  arcengine_ss_host = str(sys.argv[5])

  datacollector_host = arcviz_host # Deploy StreamSets on the same host as ArcViz

  try:
    print "Fetching API resource from: " + cm_host
    api = ApiResource(cm_host, 7180)
    print "Retrieving cluster from API resource..."
    cluster = api.get_cluster("Cluster 1") # TODO: This should not be hardcoded but I'm lazy
    #print "Stopping cluster..."
    #cluster.stop().wait()
    #print "Starting cluster..."
    #cluster.start().wait()
    print "Upgrading Hive..."
    upgrade_hive(cluster)
    print "Deploying Arcadia parcel..."
    deploy_arcadia_parcel(cluster)
    print "Deploying StreamSets parcel..."
    deploy_streamsets_parcel(cluster)
    # TODO: adding the service was doing weird stuff...creating a random role config group for kudu
    print "Adding Arcadia Enterprise service..."
    add_arcadia_service(cluster, arcengine_hosts, arcviz_host, arcengine_cat_host, arcengine_ss_host)
    print "Adding StreamSets service..."
    add_streamsets_service(cluster, datacollector_host)
    print "Complete!"
    return 0

  except KeyboardInterrupt:
    ### handle keyboard interrupt ###
    return 0
  except Exception, e:
    if DEBUG or TESTRUN:
        raise(e)
    indent = len(program_name) * " "
    sys.stderr.write(program_name + ": " + repr(e) + "\n")
    sys.stderr.write(indent + "  for help use --help")
    return 2


if __name__ == "__main__":
  if DEBUG:
    sys.argv.append("-h")
    sys.argv.append("-v")
    sys.argv.append("-r")
  if TESTRUN:
    import doctest
    doctest.testmod()
  if PROFILE:
    import cProfile
    import pstats
    profile_filename = 'parcel_test_profile.txt'
    cProfile.run('main()', profile_filename)
    statsfile = open("profile_stats.txt", "wb")
    p = pstats.Stats(profile_filename, stream=statsfile)
    stats = p.strip_dirs().sort_stats('cumulative')
    stats.print_stats()
    statsfile.close()
    sys.exit(0)
  sys.exit(main())
