generic_cloud {'mycloud-web':
   pool   => ["155.210.155.70"],
   ensure => stopped,
   provider => web,
}
