package {
   'ruby1.8-dev':        ensure => present;
   'libmysqlclient-dev': ensure => present;
   
   # Gems: rubygems, mysql, sinatra, activerecord.
   'rubygems':     provider => "gem", ensure => "1.8.21";
   'mysql':        provider => "gem", ensure => present;
   'sinatra':      provider => "gem", ensure => present;
   'activerecord': provider => "gem", ensure => present;
}


