# Package, file and service
package { 'mysql-server':
   ensure => present,
}

file { '/etc/mysql/my.cnf':
   require => Package['mysql-server'],
}

service { 'mysqld':
   ensure => running,
   enable => true,
   hasstatus => true,
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

