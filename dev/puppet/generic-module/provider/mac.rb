# MAC address
class MAC_Address
   
   attr_reader :mac
   
   # Creates a new MAC_Address object.
   def initialize(value=nil)
      @mac = value ? value: "52:54:00:00:00:00"
   end
   
   
   # Obtains the next MAC address.
   def next_mac
   
      mac_string = @mac.delete(":")
      mac_int = mac_string.to_i(16)
      mac_int += 1
      mac_hex = mac_int.to_s(16)
      result = mac_hex[0..1] + ":" + mac_hex[2..3] + ":" + mac_hex[4..5] + ":" + 
               mac_hex[6..7] + ":" + mac_hex[8..9] + ":" + mac_hex[10..11]
      return result
      
   end
   
   
   # Generates an array of <many> MAC addresses starting from this one.
   # def generate_array(many)
   
   #    result = []
   #    result << @mac
   #    for i in 1..many
   #       mac = MAC_Address.new(result[i - 1])
   #       result << mac.next_mac
   #    end
   #    return result
   
   # end
   
   
end
