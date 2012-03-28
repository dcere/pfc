#!/usr/bin/env ruby

require 'puppet'
resource = Puppet::Type.type(:cloud).new :name => "testing-cloud"
provider = resource.provider
provider.exists?
