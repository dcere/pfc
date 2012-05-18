cloud {'mycloud':
   type     => "appscale",
   ip_file  => "/etc/puppet/modules/cloud/files/appscale-1-node.yaml",
   img_file => "/etc/puppet/modules/cloud/files/appscale-1-node.yaml",
   domain  => "/etc/puppet/modules/cloud/files/mycloud-template.xml",
   pool    => ["155.210.155.70"],
   ensure  => running,
}
