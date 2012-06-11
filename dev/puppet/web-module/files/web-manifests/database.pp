# Package, file and service
package { 'mysql-server':
   ensure => present,
}

file { '/etc/mysql/my.cnf':
   require => Package['mysql-server'],
}

service { 'mysql':
   ensure => running,
   enable => true,
   hasstatus => true,
   require => Package["mysql-server"],
   hasrestart => true,
   restart => "/usr/bin/service mysql restart"
}

# User and group
user { "mysql":
   ensure => present,
   gid => "mysql",
   shell => "/bin/false",
   require => Group["mysql"],
}

group { "mysql":
   ensure => present,
}

