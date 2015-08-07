require_relative "spec_helper"

RSpec.describe "slash-vacation" do
  let(:date_format) { "%B %-d, %Y" }

  it "should respond to the root GET" do
    get "/"
    expect(last_response.body).to match /<p>Slack slash command vacation tracking\.<\/p>/
  end

  context "POST '/'" do
    let(:token) { 'test' }
    context "usage" do
      it "should output usage help with no command given" do
        post "/", token: token, text: ""
        expect(last_response.body).to eq <<-EOM
*USAGE*
>• list :slack: list all future out of office plans
>• list @username :slack: list all future out of office plans for username
>• list #channel :slack: list all future out of office plans for users in channel
>• wfh 8/10/2015-8/11/2015 my notes :slack: create work from home entry. End date and notes are optional
>• out 8/10/2015-8/11/2015 my notes :slack: create vacation entry. End date and notes are optional
>• rm wfh 8/10 :slack: delete a work from home entry starting on that date
>• rm out 8/10 :slack: delete a vacation entry starting on that date
        EOM
      end
    end
    context "list" do
      it "should check the token and reject bad requests" do
        post "/", token: 'bad', text: "list"
        expect(last_response.status).to eq 401
      end

      it "should be successful" do
        post "/", token: token, text: "list"
        expect(last_response.status).to eq 200
      end

      it "should give an error message when parsing fails" do
        post "/", token: token, text: 'fail'
        expect(last_response.status).to eq 500
        expect(last_response.body).to eq "Expected one of 'wfh', 'out', 'rm', 'list' at line 1, column 1 (byte 1)"
      end

      it "gives a message when everyone is present" do
        OooEntry.where.delete
        post "/", token: token, text: "list"
        expect(last_response.body).to eq ":metal: everyone's around :metal:"
      end

      context "with results" do
        let(:today) { Date.today }
        let(:next_month) { today >> 1 }
        before(:each) do
          OooEntry.where.delete
          OooEntry.create slack_id: 'U2345', slack_name: 'tash', type: 'wfh', start_date: next_month, end_date: next_month, note: ''
          OooEntry.create slack_id: 'U1234', slack_name: 'rahearn', type: 'wfh', start_date: today, end_date: today, note: 'afternoon only'
        end

        it "should join OooEntries with new lines" do
          post "/", token: token, text: "list"
          expect(last_response.body).to eq <<-EOM.strip
>• @rahearn is _working from home_ on *#{today.strftime date_format}* (afternoon only)
>• @tash is _working from home_ on *#{next_month.strftime date_format}*
          EOM
        end
        it "should limit results to just the given username" do
          post "/", token: token, text: "list @rahearn"
          expect(last_response.body).to eq <<-EOM.strip
>• @rahearn is _working from home_ on *#{today.strftime date_format}* (afternoon only)
          EOM
        end
      end
    end
    context "work from home" do
      before(:each) { OooEntry.where.delete }
      it "should create a db entry" do
        expect { post "/", token: token, text: 'wfh 8/10 morning only', user_id: 'U1234', user_name: 'rahearn' }.to \
          change(OooEntry, :count).from(0).to 1
      end
      it "should respond with an emoji" do
        post "/", token: token, text: 'wfh 8/10 morning only', user_id: 'U1234', user_name: 'rahearn'
        expect(last_response.status).to eq 201
        expect(last_response.body).to eq ":thumbsup:"
      end
    end
    context "delete" do
      let(:today) { Date.today }
      let(:short) { today.strftime "%m/%d/%Y" }
      before(:each) do
        OooEntry.where.delete
        OooEntry.create slack_id: 'U1234', slack_name: 'rahearn', type: 'out', start_date: today, end_date: today, note: ''
        OooEntry.create slack_id: 'U1234', slack_name: 'rahearn', type: 'wfh', start_date: today, end_date: today, note: ''
        OooEntry.create slack_id: 'U2345', slack_name: 'tash', type: 'out', start_date: today, end_date: today, note: ''
      end
      it "should remove only my matching vacation" do
        expect {
          post "/", token: token, text: "rm out #{short}", user_id: 'U1234', user_name: 'rahearn'
        }.to change(OooEntry, :count).from(3).to 2
      end
      it "should respond with a success message" do
        post "/", token: token, text: "rm out #{short}", user_id: 'U1234', user_name: 'rahearn'
        expect(last_response.status).to be 200
        expect(last_response.body).to eq ">• @rahearn is _working from home_ on *#{today.strftime date_format}*"
      end
      it "should give an emoji when clearing the last of your entries" do
        post "/", token: token, text: "rm out #{short}", user_id: 'U2345', user_name: 'tash'
        expect(last_response.body).to eq "No leave scheduled anymore. :thumbsup:"
      end
    end
  end
end
