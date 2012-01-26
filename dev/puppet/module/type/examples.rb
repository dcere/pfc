      newproperty(:ipaddr, :array_matching => :all) do
         desc "IP address(es) of the VE."

         validate do |ip|
            unless ip =~ /^\d+\.\d+\.\d+\.\d+$/
               raise ArgumentError, "\"#{ip}\" is not a valid IP address."
            end
         end

         def insync?(current)
            current.sort == @should.sort
         end
      end


      newproperty(:cpus, :parent => VirtNumericParam) do
         desc "Number of virtual CPUs active in the guest domain."

         defaultto(1)
      end

      newproperty(:cpuunits, :parent => VirtNumericParam, :required_features => :cpu_fair) do
         desc "CPU weight for a guest. Argument is positive non-zero number, passed to and used in the kernel fair scheduler.
         The larger the number is, the more CPU time this guest gets.
         Maximum value is 500000, minimal is 8. Number is relative to weights of all the other running guests.
         If cpuunits are not specified, default value of 1000 is used."
      end

      newparam(:arch) do
         desc "The domain's installation architecture. Not Changeable"

         newvalues("i386","i686","amd64","ia64","powerpc","hppa")
      end
