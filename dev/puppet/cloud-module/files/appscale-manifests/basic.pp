###############################################################################
# AppScale root directory

file { '/root/appscale':
   ensure => directory,
}

file { '/root/appscale/.appscale':
   ensure => directory,
}

###############################################################################
# AppScale basic roles

file { '/root/appscale/AppController':
   ensure => directory,
}

file { '/root/appscale/AppDB':
   ensure => directory,
}

file { '/root/appscale/AppLoadBalancer':
   ensure => directory,
}

file { '/root/appscale/AppMonitoring':
   ensure => directory,
}

file { '/root/appscale/AppServer':
   ensure => directory,
}

file { '/root/appscale/AppServer_Java':
   ensure => directory,
}

file { '/root/appscale/Neptune':
   ensure => directory,
}

###############################################################################
# AppScale programs

file { '/usr/bin/god':
   ensure => present,
}

file { '/usr/bin/mongrel_rails':
   ensure => present,
}

file { '/usr/sbin/nginx':
   ensure => present,
}
