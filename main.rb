require "sinatra"
require 'sequel'
require_relative "parser"

TOKEN = ENV["SV_TOKEN"]
DB = Sequel.connect ENV['DATABASE_URL']

require_relative "models/ooo_entry"

get "/" do
  "Slack slash command vacation tracking"
end

post "/" do
  if params[:token] != TOKEN
    return [401, ""]
  end

  input = params[:text].blank? ? "list" : params[:text]
  begin
    tree = Parser.new(input).parse
  rescue ParseError => pe
    return [500, pe.message]
  end

  if tree.list?
    # output the list of vacations
    "list"
  else
    # save a new record
    details = tree.details
    "#{tree.type.text_value}: #{details.date_range.inspect} (#{details.note})"
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
