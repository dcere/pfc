package { 'nginx':
   ensure => present,
}

file { '/etc/nginx/nginx.cnf':
   require => Package['nginx'],
}

service { 'nginx':
   ensure => running,
   enable => true,
   hasstatus => true,
   require => Package['nginx'],
}
