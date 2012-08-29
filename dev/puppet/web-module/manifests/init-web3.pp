web {'mycloud':
   balancer  => ["155.210.155.175", "/var/tmp/dceresuela/lucid-lb.img"],
   server    => ["/etc/puppet/modules/web/files/server-ips.txt", "/etc/puppet/modules/web/files/server-imgs.txt"],
   database  => ["155.210.155.177", "/var/tmp/dceresuela/lucid-db.img"],
   vm_domain => "/etc/puppet/modules/web/files/mycloud-template.xml",
   pool      => ["155.210.155.70", "155.210.155.77"],
   ensure    => running,
}
