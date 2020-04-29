describe "UserRules" do
  let(:user1) { User.create }
  let(:user2) { User.create }
  let(:user3) { User.create }

  before do
    user1.update friends: [user2]
    user2.update friends: [user3]
  end

  context "when user1" do
    let(:subject) { user1 }

    context "when visited by user2" do
      let(:user) { user2 }
      it { expect(user).to be_able_to :see_timeline, subject }
    end

    context "when visited by user3" do
      let(:user) { user3 }
      it { expect(user).not_to be_able_to :see_timeline, subject }
    end
  end

  it "allows anyone to sign in" do
    # demonstrating single argument
    expect(UserRules.can?(:sign_in)).to be_truthy

    # demonstrating passing nil explicitly (eg: when can't
    # find the record from the database)
    expect(UserRules.can?(nil, :sign_in)).to be_truthy

    # demonstrating passing user instance
    expect(UserRules.can?(user1, :sign_in)).to be_truthy
    expect(UserRules.can?(user2, :sign_in)).to be_truthy
    expect(UserRules.can?(user3, :sign_in)).to be_truthy
    expect(UserRules.cant?(user1, :sign_in)).to be_falsey
    expect(UserRules.cant?(user2, :sign_in)).to be_falsey
    expect(UserRules.cant?(user3, :sign_in)).to be_falsey
  end

  it "disallows anyone from spamming" do
    expect(UserRules.can?(:spamming)).to be_falsey
    expect(UserRules.can?(nil, :spamming)).to be_falsey

    expect(UserRules.can?(user1, :spamming)).to be_falsey
    expect(UserRules.can?(user2, :spamming)).to be_falsey
    expect(UserRules.can?(user3, :spamming)).to be_falsey

    expect(UserRules.cant?(user1, :spamming)).to be_truthy
    expect(UserRules.cant?(user2, :spamming)).to be_truthy
    expect(UserRules.cant?(user3, :spamming)).to be_truthy
  end
end
