describe "UserRules" do
  let(:user1) { User.new }
  let(:user2) { User.new }
  let(:user3) { User.new }

  before do
    user1.friends << user2
    user2.friends << user3
  end

  context "when user1" do
    let(:subject) { user1 }

    context "when visited by user2" do
      let(:user) { user2 }
      it { expect_can :see_timeline }
    end

    context "when visited by user3" do
      let(:user) { user3 }
      it { expect_cant :see_timeline }
    end
  end

  it "allows anyone to sign in" do
    expect(user1.can?(:sign_in)).to be_truthy
    expect(user2.can?(:sign_in)).to be_truthy
    expect(user3.can?(:sign_in)).to be_truthy

    expect(user1.cant?(:sign_in)).to be_falsey
    expect(user2.cant?(:sign_in)).to be_falsey
    expect(user3.cant?(:sign_in)).to be_falsey
  end

  it "disallows anyone from spamming" do
    expect(user1.can?(:spamming)).to be_falsey
    expect(user2.can?(:spamming)).to be_falsey
    expect(user3.can?(:spamming)).to be_falsey

    expect(user1.cant?(:spamming)).to be_truthy
    expect(user2.cant?(:spamming)).to be_truthy
    expect(user3.cant?(:spamming)).to be_truthy
  end
end
