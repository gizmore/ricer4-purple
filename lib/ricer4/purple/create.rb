module Ricer4::Plugins::Purple
  class Create < Ricer4::Plugin
    
    connector_is :shell
    trigger_is "purple.create"
    has_usage '<purple_connector> <string|named:"username"> <string|named:"password">'
    def execute(connector, username, password)
      
    end

  end
end
