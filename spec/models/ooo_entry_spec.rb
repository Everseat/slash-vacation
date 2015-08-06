require_relative '../spec_helper'

RSpec.describe OooEntry do

  let(:note) { "morning only" }
  subject do
    described_class.new slack_id: 'U1234',
                        slack_name: 'rahearn',
                        type: type,
                        start_date: start_date,
                        end_date: end_date,
                        note: note
  end
  let(:date_format) { "%B %-d, %Y" }

  describe "#to_s" do
    context "wfh" do
      let(:type) { "wfh" }
      context "single day" do
        let(:start_date) { Date.today }
        let(:end_date) { start_date }
        it "returns a nicely formatted summary" do
          expect(subject.to_s).to eq ">• @rahearn is _working from home_ on *#{start_date.strftime date_format}* (#{note})"
        end
      end
      context "date range" do
        let(:start_date) { Date.today }
        let(:end_date) { start_date >> 1 }
        let(:note) { "" }
        it "returns a nicely formatted summary" do
          expect(subject.to_s).to eq \
            ">• @rahearn is _working from home_ from *#{start_date.strftime date_format}* to *#{end_date.strftime date_format}*"
        end
      end
    end
    context "out" do
      let(:type) { "out" }
      let(:start_date) { Date.today }
      let(:end_date) { start_date }
      it "returns a nicely formatted summary" do
        expect(subject.to_s).to eq ">• @rahearn is _out_ on *#{start_date.strftime date_format}* (morning only)"
      end
    end
  end
end
