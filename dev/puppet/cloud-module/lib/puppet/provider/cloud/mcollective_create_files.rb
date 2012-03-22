def mcollective_create_files(path, content)

   require 'mcollective'
   include MCollective::RPC

   mc = rpcclient("files")
   printrpc mc.create(:path => path, :content => content)
   mc.disconnect

end
