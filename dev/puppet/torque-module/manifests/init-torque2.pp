torque {'mycloud':
   head      => ["155.210.155.73", "/var/tmp/dceresuela/lucid-tor1.img"],
   compute   => ["/etc/puppet/modules/torque/files/compute-ips.txt", "/etc/puppet/modules/torque/files/compute-imgs.txt"],
   vm_domain => "/etc/puppet/modules/torque/files/mycloud-template.xml",
   pool      => ["155.210.155.70"],
   ensure    => running,
}
