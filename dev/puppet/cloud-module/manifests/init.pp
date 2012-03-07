cloud {'mycloud':
   type    => "appscale",
   file    => "/etc/puppet/modules/cloud/files/appscale-1-node.yaml",
   images  => ["/var/tmp/dceresuela/lucid-appscale-tr1.img"],
   domain  => "/etc/puppet/modules/cloud/files/mycloud-template.xml",
   pool    => ["155.210.155.70"],
   ensure  => running,
}
