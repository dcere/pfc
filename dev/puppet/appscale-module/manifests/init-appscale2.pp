appscale {'mycloud':
   master    => ["155.210.155.73",
                 "/var/tmp/dceresuela/lucid-appscale-tr1.img"],
   appengine => ["/etc/puppet/modules/appscale/files/appengine-ips.txt",
                 "/etc/puppet/modules/appscale/files/appengine-imgs.txt"],
   database  => ["/etc/puppet/modules/appscale/files/database-ips.txt",
                 "/etc/puppet/modules/appscale/files/database-imgs.txt"],
   login     => ["155.210.155.73",
                 "/var/tmp/dceresuela/lucid-appscale-tr1.img"],
   open      => ["/etc/puppet/modules/appscale/files/open-ips.txt",
                 "/etc/puppet/modules/appscale/files/open-imgs.txt"],
   pool      => ["155.210.155.70"],
   ensure    => running,
}
