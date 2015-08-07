require "sinatra"
require "sequel"
require_relative "parser"

TOKEN = ENV["SV_TOKEN"]
DB = Sequel.connect ENV["DATABASE_URL"]

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
    data_set = OooEntry.where { start_date >= Date.today }
    data_set = data_set.where(slack_name: tree.username) if tree.limited?
    if data_set.count == 0
      ":metal: #{tree.limited? ? tree.username : "everyone"}'s around :metal:"
    else
      data_set.order(:start_date).map(&:to_s).join "\n"
    end
  elsif tree.delete?
    start_date = tree.details.date_range.first
    OooEntry.where(start_date: start_date, type: tree.type, slack_id: params[:user_id]).destroy
    data_set = OooEntry.where { start_date >= Date.today }.where slack_id: params[:user_id]
    if data_set.count == 0
      "No leave scheduled anymore. :thumbsup:"
    else
      data_set.order(:start_date).map(&:to_s).join "\n"
    end
  else
    details = tree.details
    OooEntry.create slack_id: params[:user_id],
                    slack_name: params[:user_name],
                    type: tree.type,
                    start_date: details.date_range.first,
                    end_date: details.date_range.last,
                    note: details.note
    [201, ":thumbsup:"]
  end
end

=begin example slash command input
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
