cloud {'mycloud':
   type     => "jobs",
   ip_file  => "/etc/puppet/modules/cloud/files/jobs-ip.yaml",
   img_file => "/etc/puppet/modules/cloud/files/jobs-img.yaml",
   domain   => "/etc/puppet/modules/cloud/files/mycloud-template.xml",
   pool     => ["155.210.155.70"],
   ensure   => running,
}
