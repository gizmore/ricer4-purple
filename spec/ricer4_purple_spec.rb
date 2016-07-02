require 'spec_helper'

describe Ricer4::Plugins::Purple do
  
  # LOAD
  bot = Ricer4::Bot.new("ricer4.spec.conf.yml")
  bot.db_connect
  ActiveRecord::Magic::Update.install
  ActiveRecord::Magic::Update.run
  bot.load_plugins
  ActiveRecord::Magic::Update.run

  it("calculates correctly") do
  end

  it("produces predictable random numbers") do
    
  end
  
end
