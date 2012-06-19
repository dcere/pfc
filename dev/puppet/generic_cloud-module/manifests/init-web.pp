generic_cloud {'mycloud-web':
   ip_file  => "/etc/puppet/modules/generic_cloud/files/web-ip.yaml",
   img_file => "/etc/puppet/modules/generic_cloud/files/web-img.yaml",
   domain   => "/etc/puppet/modules/generic_cloud/files/mycloud-template.xml",
   pool     => ["155.210.155.70"],
   ensure   => running,
   provider => web,
}
