generic_cloud {'mycloud-torque':
   ip_file  => "/etc/puppet/modules/generic_cloud/files/torque-ip.yaml",
   img_file => "/etc/puppet/modules/generic_cloud/files/torque-img.yaml",
   pool     => ["155.210.155.70"],
   ensure   => stopped,
   provider => torque,
}
