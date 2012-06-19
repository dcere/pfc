generic_cloud {'mycloud-web':
   ip_file  => "/etc/puppet/modules/generic_cloud/files/web-ip.yaml",
   img_file => "/etc/puppet/modules/generic_cloud/files/web-img.yaml",
   pool     => ["155.210.155.70"],
   ensure   => stopped,
   provider => web,
}
