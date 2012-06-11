web {'mycloud':
   ip_file  => "/etc/puppet/modules/web/files/web-ip.yaml",
   img_file => "/etc/puppet/modules/web/files/web-img.yaml",
   domain   => "/etc/puppet/modules/web/files/mycloud-template.xml",
   pool     => ["155.210.155.70"],
   ensure   => running,
}
