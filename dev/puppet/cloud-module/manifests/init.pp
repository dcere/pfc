#cloud {'mycloud':
#   instances => "10",
#   images => ["karmic-6GB-1", "karmic-6GB-2"],
#   ensure => running,
#}

cloud {'mycloud':
   instances => "1",
   images => "karmic-6GB-1",
   ensure => running,
}
