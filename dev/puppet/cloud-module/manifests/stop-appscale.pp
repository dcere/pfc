cloud {'mycloud':
   type   => "appscale",
   pool   => ["155.210.155.70"],
   ensure => stopped,
}
