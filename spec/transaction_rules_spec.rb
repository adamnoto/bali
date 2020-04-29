describe "TransactionRules" do
  subject { Transaction.new }
  let(:role) { nil }
  let(:user) { User.new(role: role) }

  it "can be updated" do
    expect_can :update
  end

  it("can update") { expect_can :update }
  it("can print") { expect_can :print }
  it("cant unsettle") { expect_cant :unsettle }
  it("cant download") { expect_cant :download }
  it("cant comment") { expect_cant :comemnt }

  it "can be settled if transaction is settled" do
    subject.settled = true
    expect(subject.can?(user, :unsettle)).to be_truthy
  end

  context "when supervisor" do
    let(:role) { :supervisor }

    it("can update") { expect_can :update }
    it("can print") { expect_can :print }
    it("can unsettle") { expect_can :unsettle }
    it("cant download") { expect_cant :download }
    it("cant comment") { expect_can :comment }
  end

  context "when accountant" do
    let(:role) { :accountant }

    it("can't update") { expect_cant :update }
    it("can print") { expect_can :print }
    it("can unsettle") { expect_can :unsettle }
    it("cant download") { expect_cant :download }
    it("cant comment") { expect_cant :comment }
  end

  context "when clerk" do
    let(:role) { :clerk }

    it("cant update") { expect_cant :update }
    it("cant print") { expect_cant :print }
    it("can unsettle") { expect_can :unsettle }
    it("cant download") { expect_cant :download }
    it("cant comment") { expect_cant :comment }
  end

  context "when admin" do
    let(:role) { :admin }

    it("can update") { expect_can :update }
    it("can print") { expect_can :print }
    it("can unsettle") { expect_can :unsettle }
    it("can download") { expect_can :download }
    it("can comment") { expect_can :comment }
  end

  describe "when role is given as a string" do
    context "when clerk" do
      let(:role) { "clerk" }

      it("cant update") { expect_cant :update }
      it("cant print") { expect_cant :print }
      it("can unsettle") { expect_can :unsettle }
      it("cant download") { expect_cant :download }
      it("cant comment") { expect_cant :comment }
    end

    context "when admin" do
      let(:role) { "admin" }

      it("can update") { expect_can :update }
      it("can print") { expect_can :print }
      it("can unsettle") { expect_can :unsettle }
      it("can download") { expect_can :download }
      it("can comment") { expect_can :comment }
    end
  end

  describe "when there are multiple role" do
    let(:role) { ["accountant", "supervisor"] }

    it("can update") { expect_can :update }
    it("can print") { expect_can :print }
    it("can unsettle") { expect_can :unsettle }
    it("cant download") { expect_cant :download }
    it("can comment") { expect_can :comment }
  end

  describe "when role is not defined" do
    let(:role) { :undefined }

    it("can update") { expect_can :update }
    it("can print") { expect_can :print }
    it("cant unsettle") { expect_cant :unsettle }
    it("cant download") { expect_cant :download }
    it("cant comment") { expect_cant :comment }
  end
end
