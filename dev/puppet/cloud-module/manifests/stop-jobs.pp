cloud {'mycloud':
   type     => "jobs",
   ip_file  => "/etc/puppet/modules/cloud/files/jobs-ip.yaml",
   img_file => "/etc/puppet/modules/cloud/files/jobs-img.yaml",
   pool     => ["155.210.155.70"],
   ensure   => stopped,
}
