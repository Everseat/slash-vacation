require_relative "spec_helper"

RSpec.describe Parser do

  subject { described_class.new data }

  context "list" do
    let(:data) { "list" }
    it "should return a parse tree" do
      expect { subject.parse }.to_not raise_error
    end
    it "should be a list command" do
      expect(subject.parse.list?).to be true
    end
  end

  context "work from home" do
    context "single day" do
      let(:data) { "wfh 8/8" }
      it "should return a parse tree" do
        expect { subject.parse }.to_not raise_error
      end
      it "should not be a list command" do
        expect(subject.parse.list?).to be false
      end

      context "#details" do
        subject { described_class.new(data).parse.details }

        it "should have an empty note" do
          expect(subject.note).to eq ""
        end
        it "should have a date range with start and end equal in the current year" do
          expected = Date.new Date.today.year, 8, 8
          expect(subject.date_range).to eq [expected, expected]
        end
      end

      context "with the year" do
        let(:data) { "wfh 8/8/2020" }
        it "should return a parse tree" do
          expect { subject.parse }.to_not raise_error
        end

        context "#details" do
          subject { described_class.new(data).parse.details }

          it "should have a date range with start and end equal" do
            expected = Date.new 2020, 8, 8
            expect(subject.date_range).to eq [expected, expected]
          end
        end
      end

      context "with a note" do
        let(:data) { "wfh 8/8 morning only" }
        it "should return a parse tree" do
          expect { subject.parse }.to_not raise_error
        end

        context "#details" do
          subject { described_class.new(data).parse.details }

          it "should have a note" do
            expect(subject.note).to eq "morning only"
          end
        end
      end
    end

    context "date range" do
      let(:data) { "wfh 8/8-8/10" }
      it "should return a parse tree" do
        expect { subject.parse }.to_not raise_error
      end

      context "#details" do
        subject { described_class.new(data).parse.details }

        it "should have a date range in the current year" do
          year = Date.today.year
          expect(subject.date_range).to eq [
            Date.new(year, 8, 8),
            Date.new(year, 8, 10)
          ]
        end
      end
    end

  end

  context "vacation" do
    let(:data) { "out 8/8 - 8/9" }
    it "should return a parse tree" do
      expect { subject.parse }.to_not raise_error
    end
  end

end
