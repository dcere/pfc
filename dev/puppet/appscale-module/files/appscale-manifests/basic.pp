################################################################################
# AppScale root directory

file { '/root/appscale':
   ensure => 'directory',
   noop   => 'true',
}

file { '/root/appscale/.appscale':
   ensure => 'directory',
   noop   => 'true',
}

################################################################################
# AppScale basic roles

file { '/root/appscale/AppController':
   ensure => 'directory',
   noop   => 'true',
}

file { '/root/appscale/AppDB':
   ensure => 'directory',
   noop   => 'true',
}

file { '/root/appscale/AppLoadBalancer':
   ensure => 'directory',
   noop   => 'true',
}

file { '/root/appscale/AppMonitoring':
   ensure => 'directory',
   noop   => 'true',
}

file { '/root/appscale/AppServer':
   ensure => 'directory',
   noop   => 'true',
}

file { '/root/appscale/AppServer_Java':
   ensure => 'directory',
   noop   => 'true',
}

file { '/root/appscale/Neptune':
   ensure => 'directory',
   noop   => 'true',
}

################################################################################
# AppScale programs

file { '/usr/bin/god':
   ensure => 'present',
   noop   => 'true',
}

file { '/usr/bin/mongrel_rails':
   ensure => 'present',
   noop   => 'true',
}

file { '/usr/sbin/nginx':
   ensure => 'present',
   noop   => 'true',
}
