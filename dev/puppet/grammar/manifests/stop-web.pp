cloud {'mycloud':
   type    => "web",
   pool    => ["155.210.155.70"],
   ensure  => stopped,
}
