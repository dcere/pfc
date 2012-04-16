cloud {'mycloud':
   type    => "web",
   file    => "/etc/puppet/modules/cloud/files/web-simple.yaml",
   images  => ["/var/tmp/dceresuela/lucid-web.img", "/var/tmp/dceresuela/lucid-db.img"],
   domain  => "/etc/puppet/modules/cloud/files/mycloud-template.xml",
   pool    => ["155.210.155.70"],
   ensure  => running,
}
