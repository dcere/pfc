#!/usr/bin/env ruby

require 'puppet'
resource = Puppet::Type.type(:appscale).new :name => "testing-cloud-appscale"
provider = resource.provider

# Might be false (if parameters are not ok) but should not raise anything
provider.exists?

# This should give you a known class
provider.class
