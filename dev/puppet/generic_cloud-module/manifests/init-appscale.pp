generic_cloud {'mycloud-appscale':
   ip_file  => "/etc/puppet/modules/generic_cloud/files/appscale-ip.yaml",
   img_file => "/etc/puppet/modules/generic_cloud/files/appscale-img.yaml",
   domain   => "/etc/puppet/modules/generic_cloud/files/mycloud-template.xml",
   pool     => ["155.210.155.70"],
   ensure   => running,
   provider => appscale,
}
