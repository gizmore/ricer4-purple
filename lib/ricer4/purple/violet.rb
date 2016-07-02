# Violet is an abstract connector for libpurple connections
# On my box, i have these protocols available:
# prpl-aim, prpl-icq, prpl-irc, prpl-msn, prpl-myspace, prpl-simple, prpl-jabber, prpl-yahoo, prpl-yahoojp
module Ricer4::Plugins::Purple
  class Violet < Ricer4::Connector

    def protocol; raise "You have to override Violet#protocol for a libpurple connector."; end
    
    def purple; bot.loader.get_plugin('Purple/Purple'); end
    
    def connect!
      ensure_inited!
      @connected = false
      if protocol_supported?(protocol)
        bot.log.info("PurpleRuby connecting as #{server.username} to #{protocol}")
        server.hostname = "#{protocol.substr_from('prpl-')}.com"
        server.save!
        @account = PurpleRuby.login(protocol, server.username, server.user_pass)
        purple.add_purple_server(@account, server)
        @connected = true
        server.set_online(true)
        while @connected
          sleep 15
        end
        sleep 30
      end
    end
    
    def ensure_inited!
      unless defined?(@@inited)
        @@inited = true
        bot.log.info("PurpleRuby init")
        PurpleRuby.init :debug => true, :user_dir => "#{Dir.pwd}/tmp/purple_users"
        @@protocols = PurpleRuby.list_protocols.collect{|p|p.id.to_s}
        bot.log.info("PurpleRuby inited")
      end
    end
    
    def protocol_supported?(protocol)
      return true if @@protocols.include?(protocol.to_s)
      bot.log.error("Purple/Violet protocol not supported in your libpurple distribution: #{protocol}")
      return false
    end
    
    def filter_text(text)
      text = (Hpricot(text)).to_plain_text.trim
      text[0] = text[0].downcase
      text
    end
    
    def watch_incoming_im(account, sender, text)
      bot.log.debug("Violet#watch_incoming_im with #{account.username}, #{sender}, #{text}")
      sender = sender.substr_to('/') || sender # discard anything after '/'
      # filter text
      text = filter_text(text)
      arm_publish("ricer/incoming", text)
      # create user
      unless user = get_user(server, sender)
        user = create_user(server, sender)
        user.permissions = Ricer4::Permission::AUTHENTICATED.bit
        user.password = '11111111'
        user.save!
      end
      user.login!
      
      # generate message
      message = Ricer4::Message.new
      message.raw = text
      message.prefix = user.hostmask = "#{sender}!#{protocol}@ricer4.violet.libpurple"
      message.type = 'PRIVMSG'
      message.args = [sender, text]
      message.server = server
      message.sender = user
      arm_publish("ricer/receive", message)
      arm_publish("ricer/received", message)
      arm_publish("ricer/messaged", message)
    end
    
    def watch_signed_on_event(account)
      bot.log.debug("Violet#watch_signed_on_event: #{account.username}")
    end
    
    def watch_connection_error(account, type, description)
      bot.log.debug("Violet#watch_connection_error: #{account.username}")
      disconnect!
    end
    
    def disconnect!
      bot.log.debug("Violet#disconnect!: #{@account.username}")
      @connected = false
      server.set_online(false)
    end
    
    def send_quit(line)
      send_to_all(line)
      disconnect!
    end
    
    def send_to_all(line)
      server.users.online.each do |user|
        @account.send_im(user.name, html_markup(line))
      end
    end

    def send_reply(reply)
      begin
        #return unless message.reply_to.is_a?(Ricer4::User)
        #@server.ricer_replies_to(message)
        @account.send_im(reply.target.name, html_markup(reply.text))
 #       @frame.sent
      rescue StandardError => e
        bot.log.info("Disconnect from #{server.hostname}: #{e.message}")
        bot.log.exception e
        disconnect!
      end
      nil
    end
    
    def html_markup(text)
      text.
        gsub("(?:\x02\x02|\x03\x03)", '').
        gsub(/\x02([^\x02]+)\x02/) { "<b>#{$1}</b>" }.
        gsub(/\x03([^\x03]+)\x03/) { "<i>#{$1}</i>" }
    end
    
  end
end
