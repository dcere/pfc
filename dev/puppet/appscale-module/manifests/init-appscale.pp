appscale {'mycloud':
   ip_file   => "/etc/puppet/modules/appscale/files/appscale-ip.yaml",
   img_file  => "/etc/puppet/modules/appscale/files/appscale-img.yaml",
   vm_domain => "/etc/puppet/modules/appscale/files/mycloud-template.xml",
   pool      => ["155.210.155.70"],
   ensure    => running,
}
