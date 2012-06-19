generic_cloud {'mycloud-appscale':
   pool     => ["155.210.155.70"],
   ensure   => stopped,
   provider => appscale,
}
