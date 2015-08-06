require_relative "spec_helper"

RSpec.describe "slash-vacation" do
  it "should respond to the root GET" do
    get "/"
    expect(last_response.body).to eq "Slack slash command vacation tracking"
  end

  context "POST '/'" do
    let(:command) { "list" }
    it "should check the token and reject bad requests" do
      post "/", token: 'bad', text: command
      expect(last_response.status).to eq 401
    end

    it "should be successful" do
      post "/", token: 'test', text: command
      expect(last_response.status).to eq 200
    end

    it "should default to list" do
      post "/", token: 'test', text: ''
      expect(last_response.status).to eq 200
    end

    it "should give an error message when parsing fails" do
      post "/", token: 'test', text: 'fail'
      expect(last_response.status).to eq 500
      expect(last_response.body).to eq "Expected one of 'wfh', 'out', 'list' at line 1, column 1 (byte 1)"
    end
  end
end
