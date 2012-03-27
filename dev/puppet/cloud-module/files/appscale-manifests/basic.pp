###############################################################################
# AppScale root directory

file { '/root/appscale':
   ensure => 'present',
   audit  => 'all',
}

file { '/root/appscale/.appscale':
   ensure => 'present',
   audit  => 'all',
}

###############################################################################
# AppScale basic roles

file { '/root/appscale/AppController':
   ensure => 'present',
   audit  => 'all',
}

file { '/root/appscale/AppDB':
   ensure => 'present',
   audit  => 'all',
}

file { '/root/appscale/AppLoadBalancer':
   ensure => 'present',
   audit  => 'all',
}

file { '/root/appscale/AppMonitoring':
   ensure => 'present',
   audit  => 'all',
}

file { '/root/appscale/AppServer':
   ensure => 'present',
   audit  => 'all',
}

file { '/root/appscale/AppServer_Java':
   ensure => 'present',
   audit  => 'all',
}

file { '/root/appscale/Neptune':
   ensure => 'present',
   audit  => 'all',
}

###############################################################################
# AppScale programs

file { '/usr/bin/god':
   ensure => 'present',
   audit  => 'all',
}

file { '/usr/bin/mongrel_rails':
   ensure => 'present',
   audit  => 'all',
}

file { '/usr/sbin/nginx':
   ensure => 'present',
   audit  => 'all',
}
