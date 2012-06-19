web {'mycloud':
   ip_file  => "/etc/puppet/modules/web/files/web-ip.yaml",
   img_file => "/etc/puppet/modules/web/files/web-img.yaml",
   pool     => ["155.210.155.70"],
   ensure   => stopped,
}
