class Message

   attr_accessor :node, :uuid, :text
   
   def initialize(node=nil, uuid=nil, text=nil)
      @node = node
      @uuid = uuid
      @text = text
   end
   
   def print
      puts "|#{@node}|#{@uuid}|#{@text}|"
   end

end
