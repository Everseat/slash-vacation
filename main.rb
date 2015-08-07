require "sinatra"
require "sequel"
require "securerandom"

configure do
  set :slack_token, ENV["SV_TOKEN"]
  set :slack_client_id, ENV["SV_CLIENT_ID"]
  set :slack_client_secret, ENV["SV_CLIENT_SECRET"]
  set :slack_team_id, ENV["SV_TEAM_ID"]
  set :session_secret, ENV["SESSION_SECRET"]
  set :method_override, true
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
  if session[:user_id]
    redirect to('/ooo_entries')
    return
  end
  session[:auth_state] = SecureRandom.hex
  <<-EOM
<p>Slack slash command vacation tracking.</p>
<p><a href="https://slack.com/oauth/authorize?client_id=#{settings.slack_client_id}&scope=identify,read,admin&state=#{session[:auth_state]}&team=#{settings.slack_team_id}&redirect_uri=#{settings.auth_uri}">Authorize</a>
here to manage your team</p>
  EOM
end

post "/logout" do
  session[:user_id] = nil
  redirect to("/"), 303
end

get "/ooo_entries" do
  return [401, "Unauthorized"] if session[:user_id].nil?

  @entries = OooEntry.where { start_date >= Date.today }.order :start_date
  haml :'ooo_entries/index.html'
end

get "/ooo_entries/new" do
  return [401, "Unauthorized"] if session[:user_id].nil?
  haml :'ooo_entries/form.html'
end

post "/ooo_entries" do
  return [401, "Unauthorized"] if session[:user_id].nil?

  client = SlackClient.new
  user = client.user params[:user_name]
  if user
    OooEntry.create slack_id: user["id"],
                    slack_name: user["name"],
                    type: params[:type],
                    start_date: Date.parse(params[:start_date]),
                    end_date: Date.parse(params[:end_date]),
                    note: params[:note]
  end
  redirect to('/ooo_entries'), 303
end

delete "/ooo_entries/:id" do
  return [401, "Unauthorized"] if session[:user_id].nil?
  OooEntry.where(id: params[:id]).delete
  redirect to('/ooo_entries'), 303
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
    token = AccessToken.create created_at: Time.now.utc, access_token: client.token
    session[:user_id] = token.id
    redirect to('/'), 303
  else
    [500, "Error retrieving token"]
  end
end

post "/" do
  if params[:token] != settings.slack_token
    return [401, ""]
  end
  if params[:text].blank?
    return <<-USAGE
*USAGE*
>• list :slack: list all future out of office plans
>• list @username :slack: list all future out of office plans for username
>• list #channel :slack: list all future out of office plans for users in channel
>• wfh 8/10/2015-8/11/2015 my notes :slack: create work from home entry. End date and notes are optional
>• out 8/10/2015-8/11/2015 my notes :slack: create vacation entry. End date and notes are optional
>• rm wfh 8/10 :slack: delete a work from home entry starting on that date
>• rm out 8/10 :slack: delete a vacation entry starting on that date
    USAGE
  end

  begin
    tree = Parser.new(params[:text]).parse
  rescue ParseError => pe
    return [500, pe.message]
  end

  if tree.list?
    data_set = OooEntry.where { start_date >= Date.today }
    data_set = data_set.where(slack_name: tree.user) if tree.query_by_user?
    if tree.query_by_channel?
      client = SlackClient.new
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
