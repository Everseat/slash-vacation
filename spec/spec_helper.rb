require 'rack/test'
require 'rspec'

ENV['RACK_ENV'] = 'test'
ENV['SV_TOKEN'] = 'test'

require File.expand_path '../../main.rb', __FILE__

module RSpecMixin
  include Rack::Test::Methods
  def app() Sinatra::Application end
end

RSpec.configure do |config|
  config.order = :random
  config.include RSpecMixin
end
