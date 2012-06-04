cloud {'mycloud':
   type   => "jobs",
   pool   => ["155.210.155.70"],
   ensure => stopped,
}
