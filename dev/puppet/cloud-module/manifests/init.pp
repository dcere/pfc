cloud {'mycloud':
   type    => "appscale",
   file    => "../files/appscale.yaml",
   image   => "karmic-6GB-1",
   domain  => "../files/description.xml",
   pool    => ["155.210.155.70"],
   ensure  => running,
}
