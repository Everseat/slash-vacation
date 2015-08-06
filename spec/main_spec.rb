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
        expect(last_response.body).to eq "Expected one of 'wfh', 'out', 'list' at line 1, column 1 (byte 1)"
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
  end
end
