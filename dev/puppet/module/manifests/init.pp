cloud {'mycloud':
   instances => "10",
   ensure => running,
}

#file {'/tmp/test2':
#  ensure => directory,
#  mode   => 0644,
#}
