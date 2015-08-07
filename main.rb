require "sinatra"
require "sequel"
require "securerandom"

configure do
  set :slack_token, ENV["SV_TOKEN"]
  set :slack_client_id, ENV["SV_CLIENT_ID"]
  set :slack_client_secret, ENV["SV_CLIENT_SECRET"]
  set :slack_team_id, ENV["SV_TEAM_ID"]
  set :session_secret, ENV["SESSION_SECRET"]
end
configure :production, :test do
  DB = Sequel.connect ENV["DATABASE_URL"]
  set :auth_uri, ENV["SV_AUTH_URI"]
end
configure :development do
  connection_string = ENV["DATABASE_URL"] || "postgresql://localhost/slash-vacation_development"
  DB = Sequel.connect connection_string
  set :auth_uri, "http://slash-vacation.dev/auth"
end

require_relative "parser"
require_relative "models/ooo_entry"
require_relative "models/access_token"
require_relative "models/slack_client"

enable :sessions

get "/" do
  session[:auth_state] = SecureRandom.hex
  <<-EOM
<p>Slack slash command vacation tracking.</p>
<p><a href="https://slack.com/oauth/authorize?client_id=#{settings.slack_client_id}&scope=identify,read,admin&state=#{session[:auth_state]}&team=#{settings.slack_team_id}&redirect_uri=#{settings.auth_uri}">Authorize</a>
here to manage your team</p>
  EOM
end

get "/auth" do
  if session[:auth_state] != params[:state]
    redirect to('/'), 302
    return
  end

  client = SlackClient.new
  client.exchange_token client_id: settings.slack_client_id,
                        client_secret: settings.slack_client_secret,
                        code: params[:code],
                        redirect_uri: settings.auth_uri
  if client.token
    # only keeping one access token around for now
    AccessToken.where.delete
    AccessToken.create created_at: Time.now.utc, access_token: client.token
    "Success"
  else
    [500, "Error retrieving token"]
  end
end

post "/" do
  if params[:token] != settings.slack_token
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
    data_set = data_set.where(slack_name: tree.user) if tree.query_by_user?
    if tree.query_by_channel?
      client = SlackClient.new AccessToken.first.access_token
      data_set = data_set.where slack_id: client.users_in_channel(tree.channel)
    end
    if data_set.count == 0
      ":metal: #{tree.limited? ? tree.query : "everyone"}'s around :metal:"
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
