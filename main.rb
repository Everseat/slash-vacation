require "sinatra"
require_relative "parser"

TOKEN = ENV["SV_TOKEN"]

get "/" do
  "Slack slash command vacation tracking"
end

post "/" do
  if params[:token] != TOKEN
    return [401, ""]
  end

  tree = Parser.parse params[:text]

  if tree.list?
    # output the list of vacations
    "list"
  else
    # save a new record
    details = tree.details
    "#{tree.type}: #{details.date_range.inspect} (#{details.note})"
  end
end

=begin
token=gIkuvaNzQIHg97ATvDxqgjtO
team_id=T0001
team_domain=example
channel_id=C2147483705
channel_name=test
user_id=U2147483697
user_name=Steve
command=/weather
text=94070
=end
