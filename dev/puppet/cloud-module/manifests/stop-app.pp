cloud {'mycloud':
   type => "appscale",
   images => ["karmic-6GB-1", "karmic-6GB-2"],
   ensure => stopped,
}
