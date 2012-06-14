torque {'mycloud':
   ip_file  => "/etc/puppet/modules/torque/files/torque-ip.yaml",
   img_file => "/etc/puppet/modules/torque/files/torque-img.yaml",
   pool     => ["155.210.155.70"],
   ensure   => stopped,
}
