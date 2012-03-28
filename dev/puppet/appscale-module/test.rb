require 'puppet'
resource = Puppet::Type.type(:appscale).new :name => "testing-appscale"
provider = resource.provider
provider.exists?
