require "faraday"
require "json"

class SlackClient

  attr_accessor :token

  def initialize(token = nil)
    @token = token
  end

  def users_in_channel(name)
    channel = find_channel name
    channel["members"]
  end

  def exchange_token(args)
    response = connection.get "/api/oauth.access", args
    self.token = JSON.parse(response.body)['access_token']
  end

  private

  def find_channel(name)
    channels = JSON.parse(connection.get "/api/channels.list", token: token, exclude_archived: 1)["channels"]
    channels.find { |c| c["name"] == name }
  end

  def connection
    @connection ||= Faraday.new(url: "https://slack.com")
  end
end
