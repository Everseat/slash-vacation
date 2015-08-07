require_relative "spec_helper"

RSpec.describe "slash-vacation" do
  it "should respond to the root GET" do
    get "/"
    expect(last_response.body).to eq "Slack slash command vacation tracking"
  end

  context "POST '/'" do
    let(:token) { 'test' }
    context "list" do
      it "should check the token and reject bad requests" do
        post "/", token: 'bad', text: "list"
        expect(last_response.status).to eq 401
      end

      it "should be successful" do
        post "/", token: token, text: "list"
        expect(last_response.status).to eq 200
      end

      it "should default to list" do
        post "/", token: token, text: ''
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
        expect(last_response.body).to eq ":metal: Everyone's around :metal:"
      end

      it "should join OooEntries with new lines" do
        OooEntry.where.delete
        today = Date.new 2015, 8, 6
        next_month = Date.new 2015, 9, 6
        OooEntry.create slack_id: 'U1234', slack_name: 'rahearn', type: 'wfh', start_date: next_month, end_date: next_month, note: ''
        OooEntry.create slack_id: 'U1234', slack_name: 'rahearn', type: 'wfh', start_date: today, end_date: today, note: 'afternoon only'
        post "/", token: token, text: "list"
        expect(last_response.body).to eq <<-EOM.strip
>• @rahearn is _working from home_ on *August 6, 2015* (afternoon only)
>• @rahearn is _working from home_ on *September 6, 2015*
        EOM
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
      before(:each) do
        OooEntry.where.delete
        today = Date.new 2015, 8, 6
        OooEntry.create slack_id: 'U1234', slack_name: 'rahearn', type: 'out', start_date: today, end_date: today, note: ''
        OooEntry.create slack_id: 'U1234', slack_name: 'rahearn', type: 'wfh', start_date: today, end_date: today, note: ''
        OooEntry.create slack_id: 'U2345', slack_name: 'tash', type: 'out', start_date: today, end_date: today, note: ''
      end
      it "should remove only my matching vacation" do
        expect {
          post "/", token: token, text: 'rm out 8/6/2015', user_id: 'U1234', user_name: 'rahearn'
        }.to change(OooEntry, :count).from(3).to 2
      end
      it "should respond with a success message" do
        post "/", token: token, text: 'rm out 8/6/2015', user_id: 'U1234', user_name: 'rahearn'
        expect(last_response.status).to be 200
        expect(last_response.body).to eq ">• @rahearn is _working from home_ on *August 6, 2015*"
      end
      it "should give an emoji when clearing the last of your entries" do
        post "/", token: token, text: 'rm out 8/6/2015', user_id: 'U2345', user_name: 'tash'
        expect(last_response.body).to eq "No leave scheduled anymore. :thumbsup:"
      end
    end
  end
end
