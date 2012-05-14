cloud {'mycloud':
   type     => "web",
   ip_file  => "/etc/puppet/modules/cloud/files/web-simple-ip.yaml",
   img_file => "/etc/puppet/modules/cloud/files/web-simple-img.yaml",
   domain   => "/etc/puppet/modules/cloud/files/mycloud-template.xml",
   pool     => ["155.210.155.70"],
   ensure   => running,
}
