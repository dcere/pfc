package {
   'ruby1.8-dev':        ensure => present;
   'libmysqlclient-dev': ensure => present;
   'rubygems':           ensure => present;
   #'rubygems':           ensure => latest; # It SHOULD work, but let's not force it
   
   # Gems: rubygems, mysql, sinatra, activerecord.
   'mysql':        provider => "gem", ensure => present;
   'sinatra':      provider => "gem", ensure => present;
   'activerecord': provider => "gem", ensure => present;
}

service { 'ruby-web3':
   provider => "base",
   path => "/root/cloud/web/server/start-ruby-web3",
   binary => "/root/cloud/web/server/start-ruby-web3",
   hasstatus => false,
   ensure => running,
}
