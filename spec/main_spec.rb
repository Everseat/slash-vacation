require File.expand_path "../spec_helper.rb", __FILE__

RSpec.describe "slash-vacation" do
  it "should respond to the root GET" do
    get "/"
    expect(last_response.body).to eq "Slack slash command vacation tracking"
  end

  context "POST '/'" do
    it "should check the token and reject bad requests" do
      post "/", token: 'bad'
      expect(last_response.status).to eq 401
    end

    it "should be successful" do
      post "/", token: 'test'
      expect(last_response.status).to eq 200
    end
  end
end
