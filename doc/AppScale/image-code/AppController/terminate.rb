$:.unshift File.join(File.dirname(__FILE__), "lib")

begin
  require 'cron_helper'
  CronHelper.clear_crontab
rescue Exception
  puts "Problem with cronhelper, moving on"
end

begin
  require 'load_balancer'
  LoadBalancer.stop
rescue Exception
  puts "Problem with loadbalancer, moving on"
end

begin
  require 'monitoring'
  Monitoring.stop
rescue Exception
  puts "Problem with monitoring, moving on"
end

begin
  require 'haproxy'
  HAProxy.clear_sites_enabled
  HAProxy.stop
rescue Exception
  puts "Problem with haproxy, moving on"
end

begin
  require 'collectd'
  Collectd.clear_sites_enabled
  Collectd.clear_monitoring_data
  Collectd.stop
rescue Exception
  puts "Problem with collectd, moving on"
end

begin
  require 'nginx'
  Nginx.clear_sites_enabled
  Nginx.stop
rescue Exception
  puts "Problem with nginx, moving on"
end

begin
  require 'godinterface'
  GodInterface.shutdown
rescue Exception
  puts "Problem with god, moving on"
end

APPSCALE_HOME = ENV['APPSCALE_HOME']

begin
  require 'pbserver'
  tree = YAML.load_file("#{APPSCALE_HOME}/.appscale/database_info.yaml")
  PbServer.stop(tree[:table])
rescue Exception
  puts "Problem with pbserver, moving on"
end

`bash #{APPSCALE_HOME}/AppController/killDjinn.sh`
# we should not call appscale-controller because it is parent.
#`service appscale-controller stop`

`rm -f #{APPSCALE_HOME}/.appscale/secret.key`
#`rm -rf /tmp/*.log`
#`rm -rf /tmp/h*`
`rm -f #{APPSCALE_HOME}/.appscale/status-*`
`rm -f #{APPSCALE_HOME}/.appscale/database_info`
`rm -f #{APPSCALE_HOME}/.appscale/neptune_info.txt`
`rm -f /tmp/uploaded-apps`
`rm -f ~/.appscale_cookies`
`rm -f /var/log/appscale/*.log`
`rm -f /var/appscale/*.pid`
`rm -f /etc/appscale/appcontroller-state.json`

#Ejabberd.stop
#Ejabberd.clear_online_users

# klogd is installed on jaunty but not karmic
klogd = "/etc/init.d/klogd"
if File.exists?(klogd)
  `#{klog} stop`
end

`rm -rf /var/apps/`
`rm -rf #{APPSCALE_HOME}/.appscale/*.pid`
`rm -rf /tmp/ec2/*`
`rm -rf /tmp/*started`
`rm -rf #{APPSCALE_HOME}/appscale/`
`rm -rf /var/appscale/memcachedb/*`

`rm -rf /var/appscale/cassandra/commitlog/*`
`rm -rf /var/appscale/cassandra/data/system/*`

`rm -rf /var/appscale/zookeeper/*`

`echo "" > /root/.ssh/known_hosts` # empty it out but leave the file there

`god terminate`

# force kill processes

["memcached",
 "nginx", "haproxy", "collectd", "collectdmon", "tcpdump",
 "soap_server", "appscale_server",
 "AppLoadBalancer", "AppMonitoring",
 # AppServer
 "dev_appserver", "DevAppServerMain",
 #Blobstore
 "blobstore_server",
 # Cassandra
 "CassandraDaemon",
 # Hadoop
 "NameNode", "DataNode", "JobTracker", "TaskTracker",
 # HBase, ZooKeeper
 "HMaster", "HRegionServer", "HQuorumPeer", "QuorumPeerMain",
 "ThriftServer",
 # Hypertable
 "Hyperspace", "Hypertable.Master", "Hypertable.RangeServer", "ThriftBroker",
 "DfsBroker",
 # Memcachedb
 "memcachedb",
 # MongoDB
 "mongod", "mongo", "mongos",
 # MySQL
 "ndb_mgmd", "ndbd", "mysqld",
 # Scalaris
 "activemq",
 "beam", "epmd",
 # Voldemort
 "VoldemortServer",
# these are too general to kill
# "java", "python", "python2.6", "python2.5",
 "thin", "god", "djinn", "xmpp_receiver"
].each do |program|
  `ps ax | grep #{program} | grep -v grep | awk '{ print $1 }' | xargs -d '\n' kill -9`
end
