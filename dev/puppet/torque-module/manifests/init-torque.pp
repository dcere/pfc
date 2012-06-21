torque {'mycloud':
   ip_file   => "/etc/puppet/modules/torque/files/torque-ip.yaml",
   img_file  => "/etc/puppet/modules/torque/files/torque-img.yaml",
   vm_domain => "/etc/puppet/modules/torque/files/mycloud-template.xml",
   pool      => ["155.210.155.70"],
   ensure    => running,
}
