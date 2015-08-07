require "faraday"
require "json"

class SlackClient

  attr_accessor :token

  def initialize()
    @token = AccessToken.first.access_token rescue nil
  end

  def user(name)
    response = connection.get "/api/users.list", token: token
    if response.status == 200
      users = JSON.parse(response.body)["members"]
      users.find { |u| u["name"] == name }
    end
  end

  def users_in_channel(name)
    channel = find_channel name
    if channel
      channel["members"]
    else
      []
    end
  end

  def exchange_token(args)
    response = connection.get "/api/oauth.access", args
    self.token = JSON.parse(response.body)['access_token']
  end

  private

  def find_channel(name)
    response = connection.get "/api/channels.list", token: token, exclude_archived: 1
    if response.status == 200
      channels = JSON.parse(response.body)["channels"]
      channels.find { |c| c["name"] == name }
    end
  end

  def connection
    @connection ||= Faraday.new(url: "https://slack.com")
  end
end
