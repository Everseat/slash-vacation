require 'rack/test'
require 'rspec'

ENV['RACK_ENV'] = 'test'
ENV['SV_TOKEN'] = 'test'
ENV['DATABASE_URL'] = 'postgresql://localhost/slash-vacation_test'
ENV['SESSION_SECRET'] = '48f5c795365c7fb1e5dccd62cbc9bb91d0aeade9e82a5f7a18a819a314fe46f50ecfb2eb51790f607869b4b3ad1f4b2377b719992701db0175bdc10c8574025d'

require File.expand_path '../../main.rb', __FILE__

module RSpecMixin
  include Rack::Test::Methods
  def app() Sinatra::Application end
end

RSpec.configure do |config|
  config.order = :random
  config.include RSpecMixin
end
