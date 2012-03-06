cloud {'mycloud':
   type      => "appscale",
   file      => "../files/appscale.yaml",
   images    => "karmic-6GB-1",
   pool      => ["155.210.155.70"],
   ensure    => running,
}
