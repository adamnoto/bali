# require_relative "../../lib/bali/rspec/able_to_matcher"

describe RSpec::Matchers::BuiltIn::AbleToMatcher do
  let(:transaction) { Transaction.new }
  let(:accountant) { User.new(role: :accountant) }

  describe "#be_able_to" do
    context "when given a class" do
      it "functions as intended" do
        expect(User).to be_able_to :sign_in
        expect(User).not_to be_able_to :see_banner
      end
    end

    context "when given an object" do
      it "functions as intended" do
        expect(accountant).to be_able_to :print, transaction
        expect(accountant).to be_able_to :unsettle, transaction
        expect(accountant).not_to be_able_to :update, transaction
      end
    end

    context "when failed to match" do
      it "prints expected message" do
        begin
          expect(accountant).to be_able_to :update, transaction
        rescue RSpec::Expectations::ExpectationNotMetError => e
          expect(e.message).to eq "expected to be able to update, but actually cannot"
        end

        begin
          expect(accountant).not_to be_able_to :print, transaction
        rescue RSpec::Expectations::ExpectationNotMetError => e
          expect(e.message).to eq "expected not to be able to print, but actually can"
        end
      end
    end

    context "when using short-hand block, the description is used" do
      it {
        expect_any_instance_of(described_class).to receive(:description).once.and_wrap_original do |m|
          msg = m.call
          expect(msg).to eq "be able to update"
          msg
        end
        expect(accountant).not_to be_able_to :update, transaction
      }

      it {
        expect_any_instance_of(described_class).to receive(:description).once.and_call_original do |m|
          msg = m.call
          expect(msg).to eq "be able to unsettle"
          msg
        end
        expect(accountant).to be_able_to :unsettle, transaction
      }
    end
  end
end
