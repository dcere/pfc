cloudres cloud {'mycloud':
  type   => "web",
  ensure => stopped,
  pool   => ["155.210.155.170"],
}
